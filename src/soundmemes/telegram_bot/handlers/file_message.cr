require "./helpers/user_state"
require "../../jobs/process_file"
require "../keyboards/main_menu"

module Soundmemes
  module TelegramBot
    module Handlers
      class FileMessage < Tele::Handlers::Message
        include UserState

        def call
          case user_state.get
          when US::State::AddSoundSetName, US::State::AddSoundSetTags
            send_message(text: "A text must be sent, not attachment.")
          when US::State::AddSoundUploadFile
            # TODO: If the file is Voice, process immideately
            if message.audio || message.voice || message.document
              params = user_state.get_params

              tags = params["new_sound_tags"]
              tags = nil unless tags.size > 0

              # OPTIMIZE: What the heck? Refer to https://github.com/crystal-lang/crystal/issues/2661
              {% for t in ["audio", "voice", "document"] %}
                if message.{{t.id}}
                  Jobs::ProcessFile.dispatch(message.from.not_nil!.id, message.{{t.id}}.not_nil!.file_id, params["new_sound_name"], tags)
                end
              {% end %}

              user_state.set(US::State::MainMenu)

              send_message(
                text: "Your file is being processed.",
                reply_markup: Keyboards::MainMenu.new.to_type,
              )
            else
              send_message(text: "This attachment type is not supported yet.")
            end
          else
            # TODO: Search sound by file_id?
            send_message(text: "It's not a right time to send an attachment.")
          end
        end
      end
    end
  end
end