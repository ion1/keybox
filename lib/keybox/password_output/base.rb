module Keybox
    module PasswordOutput
        class Base
            attr_reader :highline, :say_name, :password

            AVAILABLE = false

            def self.available?
                const_get(:AVAILABLE)
            end

            def self.in_path? file
                ENV['PATH'].split(':').any? {|dir| File.exists? File.join(dir, file) }
            end

            def initialize(highline,say_name,password)
                @highline = highline
                @say_name = say_name
                @password = password
            end
        end
    end
end

