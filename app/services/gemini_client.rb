# Sends prompts to Google Gemini.
# There is no official Ruby gem for Gemini, so this uses Net::HTTP.

require "net/http"
require "json"

class GeminiClient
  API_URL = URI("https://generativelanguage.googleapis.com/v1beta/interactions")

  # Free Gemini models. Each one has a small daily limit, so if one is used up we try the next.
  MODELS = [
    "gemini-3.8-flash",
    "gemini-3.6-flash",
    "gemini-3.5-flash-lite",
    "gemini-3.1-flash-lite",
  ]

  PROMPTS_FOLDER = Rails.root.join("app/prompts")

  # Send a prompt to the AI and return the reply as text.
  # If schema is given, the AI must reply with JSON in that shape.
  def self.ask_ai(prompt_name, message, schema: nil)
    prompt = File.read(PROMPTS_FOLDER.join("#{prompt_name}.md"))

    body = { system_instruction: prompt, input: message }
    if schema
      body[:response_format] = { type: "text", mime_type: "application/json", schema: schema }
    end

    MODELS.each do |model|
      response = send_request(body.merge(model: model))

      if response.nil?
        puts "  #{model} did not answer in time, trying the next model..."
      elsif response.code == "200"
        return reply_text(JSON.parse(response.body))
      elsif response.code == "429" || response.code.start_with?("5")
        # 429 = daily limit used up, 5xx = server problem
        puts "  #{model} did not work (#{response.code}), trying the next model..."
      else
        # Any other error (for example a wrong API key) is a real problem: stop.
        raise "Gemini error #{response.code}: #{response.body}"
      end
    end

    raise "No free Gemini model is available right now. Please try again later."
  end

  # Send one request to Google. Returns nil if there is no answer within 2 minutes.
  def self.send_request(body)
    request = Net::HTTP::Post.new(API_URL)
    request["Content-Type"] = "application/json"
    request["x-goog-api-key"] = ENV.fetch("GEMINI_API_KEY")
    request.body = body.to_json

    Net::HTTP.start(API_URL.host, API_URL.port, use_ssl: true, read_timeout: 120) do |http|
      http.request(request)
    end
  rescue Net::OpenTimeout, Net::ReadTimeout
    nil
  end

  # The AI's answer is inside "steps": in the steps whose type is "model_output".
  def self.reply_text(data)
    outputs = data["steps"].select { |step| step["type"] == "model_output" }
    outputs.flat_map { |step| step["content"] }.map { |part| part["text"] }.join
  end
end
