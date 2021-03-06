require "./helpers/user_state"

module Soundmemes
  module TelegramBot
    module Handlers
      class GenericText < Tele::Handlers::Message
        include UserState

        def call
          # It's guaranteed that text's not nil
          text = message.text.not_nil!

          case user_state.get
          when US::State::AddSoundSetName
            # Assume the message text is the new sound's name
            #
            if name = validate_new_sound_name(text)
              user_state.merge_params_with({"new_sound_name" => name})
              pp user_state.get_params # TODO: Remove
              user_state.set(US::State::AddSoundSetTags)
              send_message(text: "Okay, now enter some comma-separated tags:")
            else
              send_message(text: "This name doesn't seem to be valid. Its length has to be #{NEW_SOUND_NAME_LENGTH} symbols and it can not contain quotes. Please, try again:")
            end
          when US::State::AddSoundSetTags
            # Assume the message text is a list of the new sound tags
            #
            if tags = validate_new_sound_tags(text)
              user_state.merge_params_with({"new_sound_tags" => tags})
              pp user_state.get_params # TODO: Remove
              user_state.set(US::State::AddSoundUploadFile)
              send_message(text: "Okay. Finally, send me the sound:")
            else
              send_message(text: "These tags don't seem to be valid. Their total length has to be #{NEW_SOUND_TAGS_LENGTH} symbols and they can not contain quotes.Please, try again:")
            end
          when US::State::AddSoundUploadFile
            # The apps awaits for a sound file, but got text
            # TODO: Maybe generate a sound from text?
            #
            send_message(text: "A file must be sent, not a text!")
          else
            send_message(text: "Sorry, I don't understand you.")
          end
        end

        private NEW_SOUND_NAME_LENGTH = 3..30

        private def validate_new_sound_name(text : String) : String | Nil
          return unless NEW_SOUND_NAME_LENGTH.covers?(text.size)
          return if /'/.match(text)
          text
        end

        private NEW_SOUND_TAGS_LENGTH = 1..50

        private def validate_new_sound_tags(text : String) : String | Nil
          return unless NEW_SOUND_TAGS_LENGTH.covers?(text.size)
          return if /'/.match(text)
          text
        end
      end
    end
  end
end
