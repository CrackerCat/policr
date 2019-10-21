require "./policr/**"
require "../config/*"
require "dotenv"
require "i18n"
require "digests"

Policr::CLI.def_action "Policr.start", exclude: ENV["POLICR_ENV"]? == "test"

module Policr
  ENV_PREFIX = "POLICR_BOT"

  def self.start(port, llevel, dpath, prod)
    # 扫描图片集
    scan dpath

    puts "start"
    ENV["DATABASE_HOST"] = dpath

    Dotenv.load! "config/dev.secret.env" unless prod

    I18n.load_path += ["locales/**/"]
    I18n.init
    I18n.default_locale = "zh-hans"

    Logging.init(llevel)
    Logging.info "ready to start"

    unless prod
      ENV["DIGESTS_ENV"] = "dev"
    else
      Digests.init # Default "static"
    end

    data = {
      username:           from_env("username"),
      token:              from_env("token"),
      owner_id:           from_env("owner_id"),
      community_group_id: from_env("community_group_id"),
      snapshot_channel:   from_env("snapshot_channel"),
      voting_channel:     from_env("voting_channel"),
    }
    bot = Bot.new **data
    spawn do
      Logging.info "start web"
      Web.start port.to_i, prod, bot
    end
    Logging.info "start bot"
    Cache.recompile_global_rules bot

    bot.polling
  end

  private macro from_env(var_name)
    ENV["#{ENV_PREFIX}_{{var_name.upcase.id}}"]
  end
end
