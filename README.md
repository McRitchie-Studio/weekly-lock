# weekly-lock

The Weekly Lock: one confident NFL pick, "the lock", posted every Wednesday of
the season, with a running record of hits and misses and a short write-up per
week. It lives at weekly-lock.mcritchie.studio.

This is a 2026 rebuild of Alex McRitchie's 2016 site,
[amcritchie/the_weekly_lock](https://github.com/amcritchie/the_weekly_lock)
(Rails 4, Facebook sign-in, picks against the spread). It keeps the name, the
lock and the against-the-spread record, and leaves the rest behind: no sign-in,
no database, no admin screens. It is a showcase build for the
[McRitchie Studio App Builder](https://mcritchie.studio/build).

**The 2026 season in this repo is demo data.** The matchups, lines, scores and
write-ups are invented to show how the site works. Every page says so.

## How it works

| Piece | Where |
|-------|-------|
| The season (teams, one lock per week, scores, write-ups) | `data/season-2026.yml`, the only store; there is no database |
| Loading and checking the file | `app/models/season.rb` (refuses unknown teams, gaps in the weeks, one score without the other, a posting day that is not a Wednesday) |
| One week's pick and its result against the spread | `app/models/lock.rb` |
| The record (hits-misses-pushes, win rate) | `app/models/record.rb`, computed from the scores, never typed |
| Pages | `/` this week's lock, the record, every week; `/weeks/:week` one week in full |
| The look | `app/assets/stylesheets/application.css` (plain CSS, light and dark) |
| Health check | `/up` |

A pick is against the spread: `spread: -3.5` means the team must win by 4 or
more; `spread: 3` means it may lose by 2 and still cover. The score plus the
spread above the opponent's score is a **hit**, level is a **push**, below is a
**miss**. Pushes count in the record but not in the win rate.

To post a week: add an entry to `weeks:` with the next week number, a Wednesday
`posted_on`, the teams (keys from `teams:`), `home`, `spread`, a `headline` and a
`write_up`, and leave both scores blank. It shows as pending on top of the home
page. When the game is final, fill in `team_score` and `opponent_score`.

## Develop

```bash
bundle install
bin/rails server -p 3811
bin/rails test               # unit + request + production https probe
bin/rails test:system        # the pages in headless Chrome, desktop and phone
bin/ci                       # everything CI runs
```

## Deploy

Heroku app `mcr-weekly-lock` (company account), stack heroku-26, `heroku/ruby`
buildpack, no add-ons, one Eco `web` dyno (`Procfile`; no release phase, since
there is nothing to migrate). There is no `config/credentials.yml.enc`:
production reads `SECRET_KEY_BASE` from the environment. Production forces
HTTPS from `X-Forwarded-Proto` (`assume_ssl` stays off) except `/up`, and sets
no cookie; `ProductionSslTest` boots production to prove both.

The repo runs the three-rung ladder: feature PRs go into `accepted`, then
`release`, then `main`. CI runs on every pull request and on pushes to
`accepted`, `release` and `main`.
