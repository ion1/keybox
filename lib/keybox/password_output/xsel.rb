require 'keybox/password_output/base'

module Keybox
    module PasswordOutput
        class XSel < Base
            AVAILABLE = ENV['DISPLAY'] && ENV['DISPLAY'] != "" && in_path?('xsel')

            def output
                begin
                    to_clipboards(password)

                    say_name.call
                    highline.ask(
                       "<%= color('(copied to clipboard, press any key).', :prompt) %> "
                    ) do |q|
                        q.overwrite = true
                        q.echo      = false
                        q.character = true
                    end

                    say_name.call
                    highline.say("")

                ensure
                    to_clipboards(nil)
                end
            end

            def to_clipboards(string)
                to_clipboard('--primary', string)
                to_clipboard('--clipboard', string)
            end

            def to_clipboard(param,string)
                open('|-', 'w') do |io|
                    if io.nil?
                        # In child.
                        begin
                            exec 'xsel', param, '-i'
                        ensure
                            exit 1
                        end
                    end

                    # In parent.
                    io << string if string
                end
            end
        end
    end
end

