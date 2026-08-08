require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  # 2s (Capybara's default) is enough on a local machine but has proven too
  # tight on GitHub's shared CI runners for a click -> Turbo fetch -> Rails
  # render -> DOM swap round-trip, causing intermittent false failures.
  Capybara.default_max_wait_time = 5
end
