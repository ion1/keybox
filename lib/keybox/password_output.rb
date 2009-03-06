require 'keybox/password_output/terminal'
require 'keybox/password_output/xsel'

module Keybox
    module PasswordOutput
        PREFERENCE = [
            Keybox::PasswordOutput::XSel,
            Keybox::PasswordOutput::Terminal,
        ]

        def self.output(highline,say_name,password)
            klass = PREFERENCE.find {|k| k.available? }
            klass.new(highline, say_name, password).output if klass
        end
    end
end

