require "shell"
require "tempfile"
require "../../utils/logger"
require "../../utils/time_format"
require "../interactors/create_sound"
require "tele/requests/send_voice"

module Soundmemes
  module Jobs
    class ProcessFile
      include Dispatchable
      include Utils::Logger

      @@logger_progname = "JOB"

      # In seconds
      MAXIMUM_SOUND_DURATION = 30

      def perform(telegram_user_id : Int32,
                  telegram_file_id : String,
                  sound_name : String,
                  sound_tags : String | Nil)
        input = Tele::Client.new(ENV["BOT_API_TOKEN"]).download_file(file_id: telegram_file_id)

        if input && (converted = convert_to_ogg(input))
          send_message(telegram_user_id, "This is your recently added sound. Share it and have fun!")
          begin
            response = send_voice(telegram_user_id, converted).not_nil!.as(Tele::Types::Message)
            if voice = response.voice
              Interactors::CreateSound.new(telegram_user_id, sound_name, sound_tags, voice.file_id).call
            else
              logger.error("Did not receive voice in response message!")
            end
          ensure
            # File.delete(converted.path)
          end
        else
          send_message(telegram_user_id, "Sorry, couldn't process your file. Please, try again with another one.")
        end
      end

      private def convert_to_ogg(input : IO) : File | Nil
        temp = Tempfile.new("processed")
        path = temp.path
        File.write(path, input.to_slice)
        output_path = path + ".output.ogg"

        logger.debug("Converting #{path} (#{to_kb(File.size(path))})...")
        started_at = Time.now

        begin
          Shell.run("ffmpeg -v quiet -t #{MAXIMUM_SOUND_DURATION} -i #{path} -ar 48000 -ac 1 -acodec libopus -ab 128k #{output_path}")
          logger.debug("Converted #{path} to #{output_path} (#{to_kb(File.size(path))} to #{to_kb(File.size(output_path))}) in #{Utils::TimeFormat.to_s(Time.now - started_at)}")
          File.open(output_path)
        rescue ex : Exception
          logger.error("Could not convert file #{path}!")
          nil
        ensure
          temp.unlink
        end
      end

      private def to_kb(bytes : UInt64)
        "#{(bytes.to_f / 10 ** 3).round(1)} KB"
      end

      private def send_message(chat_id, text)
        Tele::Requests::SendMessage.new(chat_id: chat_id, text: text).send(ENV["BOT_API_TOKEN"], logger)
      end

      private def send_voice(chat_id, voice)
        Tele::Requests::SendVoice.new(chat_id: chat_id, voice: voice).send(ENV["BOT_API_TOKEN"], logger)
      end
    end
  end
end
