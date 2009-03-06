require 'keybox/password_output/base'

module Keybox
    module PasswordOutput
        class Terminal < Base
            AVAILABLE = true

            def output
                say_name.call
                highline.ask(
                   "<%= color(%Q{#{password}},:private) %> <%= color('(press any key).', :prompt) %> "
                ) do |q|
                    q.overwrite = true
                    q.echo      = false
                    q.character = true
                end

                say_name.call
                highline.say("<%= color('#{'*' * 20}', :private) %>")
            end
        end
    end
end

