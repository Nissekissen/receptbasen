namespace :steps do
  desc "Re-fetch and re-parse steps for scraped recipes whose steps were saved as one unseparated blob and/or still contain raw HTML entities (recipes scraped before StructuredParser#steps_look_unseparated? and LlmParser's entity decoding covered this). Set DRY_RUN=true to only list affected recipes."
  task refetch_unseparated: :environment do
    entity_pattern = /&[a-zA-Z]+;/

    steps_broken = ->(contents) do
      next true if contents.any? { |content| content.match?(entity_pattern) }
      next false unless contents.size == 1

      contents.first.scan(/\.\s/).size >= 3 || contents.first.length > 600
    end

    affected = Recipe.done.where(owner_id: nil).where.not(source_url: nil).includes(:steps).select do |recipe|
      recipe.steps.any? && steps_broken.call(recipe.steps.map(&:content))
    end

    puts "Found #{affected.size} recipe(s) with unseparated/entity-laden steps:"
    affected.each { |recipe| puts "  ##{recipe.id} #{recipe.title} (#{recipe.source_domain})" }

    if ENV["DRY_RUN"].present?
      puts "DRY_RUN set, stopping here."
      next
    end

    affected.each_with_index do |recipe, index|
      sleep 3 if index.positive?

      connection = Faraday.new do |f|
        f.use Faraday::FollowRedirects::Middleware
        f.options.timeout = 10
        f.headers["User-Agent"] = "Mozilla/5.0 (compatible; ReceptbasenBot/1.0)"
      end

      response = connection.get(recipe.source_url)
      raise "Failed to fetch page: #{response.status}" unless response.success?

      html = response.body

      structured_parser = StructuredParser.new(html)
      result = structured_parser.call
      new_steps = result ? structured_parser.steps : nil

      if new_steps.nil?
        llm_parser = LlmParser.new(html)
        result = llm_parser.call

        if result.nil?
          puts "Recipe #{recipe.id}: FAILED to re-parse (#{llm_parser.error})"
          next
        end

        new_steps = llm_parser.steps
      end

      if steps_broken.call(new_steps)
        puts "Recipe #{recipe.id}: re-fetched, but steps are still unseparated/entity-laden — needs manual review, skipping"
        next
      end

      recipe.steps.destroy_all
      recipe.steps.create!(new_steps.each_with_index.map { |content, position| { content: content, position: position } })
      puts "Recipe #{recipe.id}: re-fetched and replaced #{new_steps.size} steps"
    rescue => e
      puts "Recipe #{recipe.id}: FAILED (#{e.class}: #{e.message})"
    end
  end
end
