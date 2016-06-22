# -*- encoding: utf-8 -*-
#
# Copyright 2016 Matt Wrock <matt@mattwrock.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'base64'
require_relative 'message'

module WinRM
  module PSRP
    # Handles decoding a raw powershell output response
    class PowershellOutputDecoder
      MESSAGE_TYPES_TO_IGNORE = [
        WinRM::PSRP::Message::MESSAGE_TYPES[:pipeline_state],
        WinRM::PSRP::Message::MESSAGE_TYPES[:information_record],
        WinRM::PSRP::Message::MESSAGE_TYPES[:progress_record]
      ].freeze

      attr_reader :message

      # Decode the raw SOAP output into decoded PSRP message,
      # Removes BOM and replaces encoded line endings
      # @param raw_output [String] The raw encoded output
      # @return [String] The decoded output
      def decode(message)
        return nil if MESSAGE_TYPES_TO_IGNORE.include?(message.type)
        return nil if message.data =~ %r{<ToString>WriteProgress</ToString>}
        decoded_text = handle_invalid_encoding(message.data)
        decoded_text = remove_bom(decoded_text)
        decoded_text = extract_out_string(decoded_text)
        decoded_text
      end

      private

      def extract_out_string(decoded_text)
        doc = REXML::Document.new(decoded_text)
        doc.root.get_elements('//S').map do |node|
          text = ''
          text << "#{node.attributes['N']}: " if node.attributes['N']
          next unless node.text
          text << node.text.gsub(/_x(\h\h\h\h)_/) do
            Regexp.last_match[1].hex.chr
          end.chomp
          text << "\r\n"
        end.join
      end

      def handle_invalid_encoding(decoded_text)
        decoded_text = decoded_text.force_encoding('utf-8')
        return decoded_text if decoded_text.valid_encoding?
        if decoded_text.respond_to?(:scrub)
          decoded_text.scrub
        else
          decoded_text.encode('utf-16', invalid: :replace, undef: :replace).encode('utf-8')
        end
      end

      def remove_bom(decoded_text)
        decoded_text.sub("\xEF\xBB\xBF", '')
      end
    end
  end
end
