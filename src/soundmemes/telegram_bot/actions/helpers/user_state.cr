require "../../user_state"

module Soundmemes
  module TelegramBot
    module Actions
      module Helpers
        module UserState
          alias US = Soundmemes::TelegramBot::UserState

          def user_state
            @user_state ||= US.new(message.from.not_nil!.id)
          end
        end
      end
    end
  end
end
