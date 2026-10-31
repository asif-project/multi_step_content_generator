# Multi-Step Content Generator (Ruby on Rails)

This app takes a short idea and turns it into finished content, for example an announcement. Instead of asking the AI once with one big prompt, it goes through 6 separate steps. Each step is its own call to Google Gemini.

Example idea: "We launched a new employee attendance feature."

This is the Rails version of my Python project. The prompts and the steps are the same.

## Screenshots

![Home](screenshots/01_home.png)

![Result](screenshots/02_result.png)

## The 6 steps

1. Understand: reads the idea and writes a brief (audience, goal, type of content, tone, key points). Answers in JSON.
2. Outline: plans the title and the sections. Answers in JSON.
3. Draft: writes the first draft.
4. Review: gives the draft a score out of 10 and lists the problems and how to fix them. Answers in JSON.
5. Improve: rewrites the draft to fix the problems from the review.
6. Final: last check of the grammar, the title and the ending.

The AI does not remember the earlier calls, so every step gets the original idea and the brief again, plus the output it needs from the earlier steps. If a detail is missing (like a date or a link), the AI writes a [placeholder] instead of making something up.

## Main files

- `app/services/gemini_client.rb` sends the prompts to Gemini. If a free model has used up its daily limit, it tries the next one.
- `app/services/content_pipeline.rb` has the 6 steps.
- `app/prompts/` has the prompt for each step.
- `app/controllers/contents_controller.rb` shows the page and handles the Generate button.
- `app/views/contents/new.html.haml` is the page.
- `app/helpers/application_helper.rb` turns the Markdown from the AI into HTML.

## How to run

You need Ruby 3.1 or newer and a free Gemini API key from https://aistudio.google.com/apikey

```bash
bundle install
cp .env.example .env    # then put your key in .env
bin/rails server
```

Then open http://localhost:3000

## Limitations

- The free Gemini models allow only about 20 requests a day each, and one run uses 6 requests.
- The page has to wait while the 6 steps run, which takes 1-2 minutes.
- The output is a bit different every time.
