# Runs 6 different ideas through all 6 steps and saves the output of every step
# in examples/<name>.md
#
# Run it with:  bin/rails test_cases
# A test case that is already saved is skipped (delete its file to run it again).

desc "Run the 6 test ideas and save every step's output in examples/"
task test_cases: :environment do
  test_cases = {
    # The example from the assignment. Few facts, so nothing should be invented.
    "01_attendance_feature" => "We launched a new employee attendance feature.",
    # A very vague idea. Step 1 has to make sensible guesses.
    "02_vague_idea" => "AI is changing things.",
    # A technical topic. The facts must stay correct.
    "03_technical_topic" => "Our engineering team moved our main database from MySQL to PostgreSQL.",
    # A short notice. Should stay short.
    "04_short_notice" => "The office will be closed next Friday for maintenance.",
    # A specific format was asked for.
    "05_linkedin_post" => "LinkedIn post about our team winning the company hackathon.",
    # An idea with real details. All the details should be used.
    "06_idea_with_details" => "We launched a new employee attendance feature for our own staff. " \
                              "Employees can now check in and out from the company mobile app with one tap, " \
                              "and managers get a weekly attendance report by email. " \
                              "It is live for everyone from 1 November.",
  }

  test_cases.each do |name, idea|
    file_path = Rails.root.join("examples", "#{name}.md")
    if File.exist?(file_path)
      puts "#{name}: already saved, skipping"
      next
    end

    puts "\n===== #{name} ====="
    results = ContentPipeline.run(idea)
    ContentPipeline.save_results(results, file_path)
    puts "Saved. Review score of the first draft: #{results[:review]['score']}/10"
  end
end
