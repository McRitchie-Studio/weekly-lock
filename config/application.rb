require_relative "boot"

require "rails"
require "active_model/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module WeeklyLock
  class Application < Rails::Application
    config.load_defaults 8.1

    config.autoload_lib(ignore: %w[assets tasks])

    # Locks post on Wednesdays, Eastern: "this week" turns over on NFL time,
    # not the server's UTC clock.
    config.time_zone = "Eastern Time (US & Canada)"

    # Public pages with no forms and no sign-in: no session, so no cookie.
    config.session_store :disabled
  end
end
