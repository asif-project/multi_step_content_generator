# ContentPipeline - turns a short idea into finished content in 6 steps.
#
#   idea -> 1 Understand -> 2 Outline -> 3 Draft -> 4 Review -> 5 Improve -> 6 Final
#
# Each step is a separate AI call with its own prompt (see app/prompts).
# The original idea and the brief are sent to every step after step 1.

class ContentPipeline
  # ---------- The shapes of the JSON answers ----------

  TEXT = { type: "string" }
  LIST_OF_TEXT = { type: "array", items: TEXT }

  BRIEF_SCHEMA = {
    type: "object",
    properties: {
      topic: TEXT,
      audience: TEXT,
      goal: TEXT,
      content_type: TEXT,
      tone: TEXT,
      key_points: LIST_OF_TEXT,
      assumptions: LIST_OF_TEXT,
    },
    required: %w[topic audience goal content_type tone key_points assumptions],
  }

  OUTLINE_SCHEMA = {
    type: "object",
    properties: {
      title: TEXT,
      sections: {
        type: "array",
        items: {
          type: "object",
          properties: { heading: TEXT, purpose: TEXT, points: LIST_OF_TEXT },
          required: %w[heading purpose points],
        },
      },
    },
    required: %w[title sections],
  }

  REVIEW_SCHEMA = {
    type: "object",
    properties: {
      score: { type: "integer" },
      strengths: LIST_OF_TEXT,
      issues: {
        type: "array",
        items: {
          type: "object",
          properties: { problem: TEXT, quote: TEXT, fix: TEXT },
          required: %w[problem quote fix],
        },
      },
    },
    required: %w[score strengths issues],
  }

  # Turn the AI's JSON text into a Ruby hash, and check that no field is missing.
  def self.parse_json(reply, schema)
    data = JSON.parse(reply)
    missing = schema[:required] - data.keys
    raise "The AI's answer is missing: #{missing.join(', ')}" if missing.any?
    data
  end

  # ---------- The 6 steps ----------

  # Step 1: idea -> brief
  def self.understand(idea)
    message = "ORIGINAL IDEA:\n#{idea}"
    reply = GeminiClient.ask_ai("01_understand", message, schema: BRIEF_SCHEMA)
    parse_json(reply, BRIEF_SCHEMA)
  end

  # Step 2: brief -> outline
  def self.make_outline(idea, brief)
    message = "ORIGINAL IDEA:\n#{idea}\n\n" \
              "BRIEF:\n#{JSON.pretty_generate(brief)}"
    reply = GeminiClient.ask_ai("02_outline", message, schema: OUTLINE_SCHEMA)
    parse_json(reply, OUTLINE_SCHEMA)
  end

  # Step 3: brief + outline -> first draft
  def self.write_draft(idea, brief, outline)
    message = "ORIGINAL IDEA:\n#{idea}\n\n" \
              "BRIEF:\n#{JSON.pretty_generate(brief)}\n\n" \
              "OUTLINE:\n#{JSON.pretty_generate(outline)}"
    GeminiClient.ask_ai("03_draft", message)
  end

  # Step 4: draft -> review (score, strengths, issues)
  def self.review_draft(idea, brief, outline, draft)
    message = "ORIGINAL IDEA:\n#{idea}\n\n" \
              "BRIEF:\n#{JSON.pretty_generate(brief)}\n\n" \
              "OUTLINE:\n#{JSON.pretty_generate(outline)}\n\n" \
              "DRAFT:\n#{draft}"
    reply = GeminiClient.ask_ai("04_review", message, schema: REVIEW_SCHEMA)
    parse_json(reply, REVIEW_SCHEMA)
  end

  # Step 5: draft + review -> improved draft
  def self.improve_draft(idea, brief, draft, review)
    message = "ORIGINAL IDEA:\n#{idea}\n\n" \
              "BRIEF:\n#{JSON.pretty_generate(brief)}\n\n" \
              "DRAFT:\n#{draft}\n\n" \
              "REVIEW:\n#{JSON.pretty_generate(review)}"
    GeminiClient.ask_ai("05_improve", message)
  end

  # Step 6: improved draft -> final version
  def self.finalize(idea, brief, improved)
    message = "ORIGINAL IDEA:\n#{idea}\n\n" \
              "BRIEF:\n#{JSON.pretty_generate(brief)}\n\n" \
              "IMPROVED DRAFT:\n#{improved}"
    GeminiClient.ask_ai("06_final", message)
  end

  # Run all 6 steps one after another.
  def self.run(idea)
    puts "Step 1: Understand"
    brief = understand(idea)
    puts "Step 2: Outline"
    outline = make_outline(idea, brief)
    puts "Step 3: Draft"
    draft = write_draft(idea, brief, outline)
    puts "Step 4: Review"
    review = review_draft(idea, brief, outline, draft)
    puts "Step 5: Improve"
    improved = improve_draft(idea, brief, draft, review)
    puts "Step 6: Final"
    final = finalize(idea, brief, improved)

    { idea: idea, brief: brief, outline: outline, draft: draft,
      review: review, improved: improved, final: final }
  end

  # Save the output of every step in one Markdown file.
  def self.save_results(results, file_path)
    text = <<~MARKDOWN
      # Idea

      #{results[:idea]}

      ---

      # Step 1: Brief

      ```json
      #{JSON.pretty_generate(results[:brief])}
      ```

      ---

      # Step 2: Outline

      ```json
      #{JSON.pretty_generate(results[:outline])}
      ```

      ---

      # Step 3: Draft

      #{results[:draft]}

      ---

      # Step 4: Review

      ```json
      #{JSON.pretty_generate(results[:review])}
      ```

      ---

      # Step 5: Improved draft

      #{results[:improved]}

      ---

      # Step 6: Final

      #{results[:final]}
    MARKDOWN
    File.write(file_path, text)
  end
end
