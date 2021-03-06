require 'autocleaver/frontmatter'

module Autocleaver
  class Renderer
    SENTENCE = /^(\w|`)/
    NUMBERS = /[0-9]/

    attr_reader :input_text, :inside_code_block

    def initialize(text)
      @input_text = text
      @inside_code_block = false
    end

    def self.load(filename)
      new(File.read(filename))
    end

    def render
      output_file = File.new("output_file.html", 'w+')
      output_file.write(generate_headers(input_text))
      output_file.write(transpile(input_text))
      output_file.close
      output_file
    end

    def transpile(text)
      text = remove_paragraphs(text)
      result = add_slide_breaks(text)
      result << "\n"
    end

    def generate_headers(text)
      Autocleaver::Frontmatter.new(text).to_s
    end

    private

    def add_slide_breaks(text)
      current_header = ""
      missing_header = true
      text.split("\n").map do |line|
        update_code_block_status(line)
        missing_header = true if closing_code_block?(line)

        if header?(line) && !inside_code_block
          current_header = line
          missing_header = false
          "--\n\n#{line}"
        elsif opening_code_block?(line) && missing_header
          "--\n\n#{current_header}\n\n#{line}"
        else
          line
        end
      end.join("\n")
    end

    def remove_paragraphs(text)
      remove_linebreak = false
      text.split("\n").map do |line|
        update_code_block_status(line)
        if remove_linebreak == true
          remove_linebreak = false
          nil
        elsif inside_code_block || closing_code_block?(line) || !is_paragraph?(line)
          line
        else
          remove_linebreak = true
          nil
        end
      end.compact.join("\n")
    end

    def is_paragraph?(line)
      line.strip.match(SENTENCE) && !line.strip.match(NUMBERS) || line == "---"
    end

    def header?(line)
      line.strip.start_with?("#")
    end

    def code_block_edge?(line)
      line.strip.start_with?("```")
    end

    def opening_code_block?(line)
      line.strip.match(/^```.+/)
    end

    def closing_code_block?(line)
      line.strip.match(/^```$/)
    end

    def update_code_block_status(line)
      @inside_code_block = true if opening_code_block?(line)
      @inside_code_block = false if closing_code_block?(line)
    end

  end
end
