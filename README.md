# Elixir School

> Elixir School is the premier destination for people seeking to learn and master the Elixir programming language.

You can access lessons at [ElixirSchool.com](https://elixirschool.com).

_Feedback and participation are strongly encouraged! Please see [Contributing](CONTRIBUTING.md) for more details on how to get involved. Be sure to review our [style guide](https://github.com/elixirschool/elixirschool/wiki/Lesson-Styleguide) before submitting changes._

### Running Locally

This repository only contains the lessons and blog posts hosted on Elixir School. To run the Elixir School website locally, find the code and setup instructions in the [school_house](https://github.com/elixirschool/school_house) repository.

### Translation Version Report

To see which translations are outdated or missing, run the version report script:

```shell
elixir bin/version_report.exs
```

Filter by language or severity:

```shell
elixir bin/version_report.exs --lang ja,es
elixir bin/version_report.exs --severity major,missing
```

### Translating a Lesson

1. Each of the languages has a folder in `lessons/` directory of this repo. To start translating you need to copy a file from the English language to the corresponding folder in your language and start translating it.

2. Use the [version report](#translation-version-report) to see pages that haven't been translated yet, or pages which need to have their translations updated:

   ```shell
   elixir bin/version_report.exs --lang <your-lang>
   ```

3. Translated lessons must include page metadata.
   * `title` should be a translation of the original lesson's `title`.
   * `version` should be set to the original English `version`.
   * `excerpt` should be a translation of the original lesson's `excerpt`.

   For example `lessons/ja/basics/basics.md`:

   ```elixir
   %{
     version: "1.0.0",
     title: "基本",
     excerpt: """
     基本についての短い説明。
     """
   }
   ---
   ```

4. Submit a PR with the new translated lesson :tada:

### Posting an Article

Elixir School is powered by Phoenix and [NimblePublisher](https://github.com/dashbitco/nimble_publisher), a publishing engine that supports Markdown formatting. If you're familiar with Phoenix & NimblePublisher then you're ready to go, if you aren't don't fret we're here to help!

1. We need to create the file for our article. Blog posts live in the `posts/` directory. Our filename will need to conform to the `YYYY-MM-DD-name-separated-with-hyphens.md` pattern.

2. After opening the new file in our favorite editor we need to add some metadata to the top of it:

```elixir
%{
  author: "Author Name",
  author_link: "https://github.com/author_github_account",
  tags: ["phoenix"],
  date: ~D[YYYY-MM-DD],
  title: "Full Article Title",
  excerpt: """
  Article short preview text
  """
}
---
```

3. Once we've completed writing our post submit a pull request to have it reviewed before it is published.


## 🌐 Web Resources & Interactive Index
- [CATEGORY SOLITAIRE27](https://studyquesthub.web.app/category-solitaire27.html)
- [WORLD Z DEFENSE ZOMBIE DEFENSE](https://thelearnquester.web.app/world-z-defense-zombie-defense.html)
- [WOOD NUTS MASTER SCREW PUZZLE](https://learnquesters.pages.dev/wood-nuts-master-screw-puzzle.html)
- [PANDA MAHJONG CLASSIC](https://studyplayings.pages.dev/panda-mahjong-classic.html)
- [CATEGORY ARCHERY52](https://learnquesters.pages.dev/category-archery52.html)
- [CHRISTMAS BLIND BOX](https://studyplayings.pages.dev/christmas-blind-box.html)
- [SITEMAP](https://learnquester.pages.dev/sitemap.html)
- [RAGDOLL JUMP](https://studyplayings.web.app/ragdoll-jump.html)
- [INDEX2](https://learnquester.pages.dev/index2.html)
- [FAIRY WINGERELLA](https://thelearnquester.web.app/fairy-wingerella.html)
- [CATEGORY TOWER DEFENSE 2](https://studyplayings.web.app/category-tower-defense-2.html)
- [ARROW COUNT MASTER](https://studyplayings.pages.dev/arrow-count-master.html)
- [DARK ACADEMIA WEDDING](https://studyplayings.pages.dev/dark-academia-wedding.html)
- [COLOR WATER PUZZLE](https://themindplays.pages.dev/color-water-puzzle.html)
- [BFFS K POP FANGIRLS](https://themindplays.pages.dev/bffs-k-pop-fangirls.html)
- [OFFICE SOLITAIRE](https://themindplays.pages.dev/office-solitaire.html)
- [CRAZY TRAFFIC RACER](https://themindplays.pages.dev/crazy-traffic-racer.html)
- [CATEGORY PREMIUM PERKS74](https://learnquester.pages.dev/category-premium-perks74.html)
- [CATEGORY MAHJONG CONNECT](https://themindplays.pages.dev/category-mahjong-connect.html)
- [CATEGORY OBSTACLE299](https://learnquester.pages.dev/category-obstacle299.html)
- [CATEGORY DESTROY256](https://skillplay.github.io/category-destroy256.html)
- [CATEGORY WEBGAME](https://learnquester.pages.dev/category-webgame.html)
- [K WEDDING DREAM](https://themindplays.pages.dev/k-wedding-dream.html)
- [CATEGORY MMO25](https://thequizzone.pages.dev/category-mmo25.html)
- [WHEEL IN THE FACE](https://thelearnquester.web.app/wheel-in-the-face.html)
- [CATEGORY CONTROLLER 2](https://iskillplay.web.app/category-controller-2.html)
- [FASHION PRINCESS DRESS UP](https://themindplays.pages.dev/fashion-princess-dress-up.html)
- [PLANET EVOLUTION IDLE CLICKER](https://learnquester.pages.dev/planet-evolution-idle-clicker.html)
- [HAMSTER COMBO IDLE](https://learnquester.github.io/hamster-combo-idle.html)
- [CAR PARK SIMULATOR](https://thelearnquesters.pages.dev/car-park-simulator.html)
- [MY TINY MARKET](https://thelearnquesters.pages.dev/my-tiny-market.html)
- [CATEGORY SHOOTER 2](https://studyplayings.web.app/category-shooter-2.html)
- [MY PARKING LOT](https://themindplays.pages.dev/my-parking-lot.html)
- [SEA MATCH](https://themindskillplayplay.pages.dev/sea-match.html)
- [CATEGORY PUZZLE 4](https://learnquester.pages.dev/category-puzzle-4.html)
- [ESCAPE FROM TUNG TUNG SAHUR](https://iskillplay.web.app/escape-from-tung-tung-sahur.html)
- [COIN EMPIRE](https://themindplays.pages.dev/coin-empire.html)
- [FARM MATCH SEASONS 3](https://thelearnquesters.pages.dev/farm-match-seasons-3.html)
- [UNTWIST ROAD](https://skillplay.github.io/untwist-road.html)
- [NEON DASH CYBER RUN](https://themindplays.pages.dev/neon-dash-cyber-run.html)
- [CELEBRITY SPRING FASHION TRENDS](https://skillplay.github.io/celebrity-spring-fashion-trends.html)
- [ULTRAHERO VS MONSTERS ROYALE BATTLE](https://themindplays.pages.dev/ultrahero-vs-monsters-royale-battle.html)
- [CATEGORY BASKETBALL 2](https://themindplays.pages.dev/category-basketball-2.html)
- [ASMR PET TREATMENT](https://iskillplay.web.app/asmr-pet-treatment.html)
- [CATEGORY SOLITAIRE27](https://skillplay.github.io/category-solitaire27.html)
- [CATEGORY PUZZLE 2](https://studyplayings.pages.dev/category-puzzle-2.html)
- [SQUID ESCAPE BUT BLOCKWORLD](https://learnquester.pages.dev/squid-escape-but-blockworld.html)
- [CATEGORY MINECRAFT](https://studyplayings.pages.dev/category-minecraft.html)
- [SLIDE BLOCK PUZZLE](https://thelearnquester.web.app/slide-block-puzzle.html)
- [CATEGORY PREMIUM PERKS71](https://learnquester.github.io/category-premium-perks71.html)
- [CATEGORY COOKING](https://studyplayings.web.app/category-cooking.html)
- [PUZZLE BLOCKS CLASSIC](https://skillplay.github.io/puzzle-blocks-classic.html)
- [SURVIVAL SWORD BATTLE](https://themindplays.pages.dev/survival-sword-battle.html)
- [CATEGORY PROXY](https://learnquester.pages.dev/category-proxy.html)
- [NONOGRAM DAILY](https://studyplayings.web.app/nonogram-daily.html)
- [SEADRAGONS IO](https://themindskillplayplay.pages.dev/seadragons-io.html)
- [RIDDLEMATH](https://studyplaying.github.io/riddlemath.html)
- [NUMBER BUBBLE SHOOTER](https://iskillplay.web.app/number-bubble-shooter.html)
- [SPIDER ROPE HERO CITY FIGHT](https://learnquester.pages.dev/spider-rope-hero-city-fight.html)
- [DALGONA GAME2](https://skillplay.github.io/dalgona-game2.html)
- [ANIME DOLL DIY COSPLAY GIRL](https://skillplay.github.io/anime-doll-diy-cosplay-girl.html)
- [CATEGORY MERGE](https://skillplay.github.io/category-merge.html)
- [CATEGORY BUBBLE SHOOTER GAMES](https://themindplays.pages.dev/category-bubble-shooter-games.html)
- [CATEGORY SOLITAIRE27](https://thelearnquester.web.app/category-solitaire27.html)
- [TRY TO COUNT THE BOXES BRAIN TRAINING](https://learnquester.pages.dev/try-to-count-the-boxes-brain-training.html)
- [DOGS VS ALIENS](https://learnquester.github.io/dogs-vs-aliens.html)
- [NOOB SHOOTER GUN BATTLE 3D](https://studyplayings.pages.dev/noob-shooter-gun-battle-3d.html)
- [MERMAIDS SPOT THE DIFFERENCES](https://themindplays.pages.dev/mermaids-spot-the-differences.html)
- [MAHJONG CUTE TILES](https://studyplaying.github.io/mahjong-cute-tiles.html)
- [FROM ZOMBIE TO GLAM A SPOOKY TRANSFORMATION](https://thelearnquester.web.app/from-zombie-to-glam-a-spooky-transformation.html)
- [DOMINO SMASH 3D](https://themindplays.pages.dev/domino-smash-3d.html)
- [EQ TEST PUZZLE](https://studyplayings.pages.dev/eq-test-puzzle.html)
- [BALL PAINT 3D](https://thelearnquesters.pages.dev/ball-paint-3d.html)
- [WOOLLOOP COLOR PUZZLE](https://skillplay.github.io/woolloop-color-puzzle.html)
- [CATEGORY QUIZ](https://learnquester.pages.dev/category-quiz.html)
- [CATEGORY SPORTS](https://thelearnquesters.pages.dev/category-sports.html)
- [CATEGORY FIGHTING124](https://themindplays.pages.dev/category-fighting124.html)
- [ARROW TAP PUZZLE](https://themindskillplayplay.pages.dev/arrow-tap-puzzle.html)
- [CATEGORY WAR](https://iskillplay.web.app/category-war.html)
- [VARIETY MECHA](https://iskillplay.web.app/variety-mecha.html)
- [CATEGORY STUNT128](https://skillplay.github.io/category-stunt128.html)
- [OFFICE ESCAPE TO DATE](https://studyplayings.pages.dev/office-escape-to-date.html)
- [MIRROR SHAPE](https://studyplayings.web.app/mirror-shape.html)
- [CLOWNFISH PIN OUT](https://thelearnquester.web.app/clownfish-pin-out.html)
- [CATEGORY WAR137](https://learnquester.pages.dev/category-war137.html)
- [IDLE FACTORY DOMINATION](https://theskillquest.pages.dev/idle-factory-domination.html)
- [PAINT MASTER](https://iskillplay.web.app/paint-master.html)
- [TAP BLOCK PUZZLE SMASH GAME](https://skillplay.github.io/tap-block-puzzle-smash-game.html)
- [MERGE 2048 GUN RUSH](https://thelearnquester.web.app/merge-2048-gun-rush.html)
- [CATEGORY SANDBOX41](https://studyplayings.web.app/category-sandbox41.html)
- [ANIMAL IN RAILS](https://themindplays.pages.dev/animal-in-rails.html)
- [FISH EAT GROW MEGA](https://studyplayings.pages.dev/fish-eat-grow-mega.html)
- [BRAINROT MERGE](https://skillplay.github.io/brainrot-merge.html)
- [PET RUNNER](https://iskillquest.pages.dev/pet-runner.html)
- [CATEGORY MINECRAFT 3](https://thelearnquesters.pages.dev/category-minecraft-3.html)
- [ANIME DRESS UP DOLL DRESS UP](https://learnquester.pages.dev/anime-dress-up-doll-dress-up.html)
- [SAVE STRANDING FISH](https://thequizzone.pages.dev/save-stranding-fish.html)
- [DETECTIVE LOGIC PUZZLES](https://studyplaying.github.io/detective-logic-puzzles.html)
- [SKINFLUENCER BEAUTY ROUTINE](https://thelearnquester.web.app/skinfluencer-beauty-routine.html)
- [TYPE SPRINT](https://studyplayings.web.app/type-sprint.html)
- [CATEGORY TANK58](https://thelearnquesters.pages.dev/category-tank58.html)
- [CUT GRASS](https://learnquester.pages.dev/cut-grass.html)
- [JUMP TO THE MOUNTAIN FOR THE BRAINROTS](https://iskillplay.web.app/jump-to-the-mountain-for-the-brainrots.html)
- [ENCHANTED MAHJONG SAGA](https://studyplayings.pages.dev/enchanted-mahjong-saga.html)
- [SOLITAIRE TAIL](https://learnquester.github.io/solitaire-tail.html)
- [RAGDOLL FOOTBALL 2 PLAYERS](https://studyplayings.web.app/ragdoll-football-2-players.html)
- [GOODS SORTING SHOPPING MASTER](https://thequizzone.pages.dev/goods-sorting-shopping-master.html)
- [OBBY TSUNAMI ESCAPE 1 BY CAR](https://studyplayings.web.app/obby-tsunami-escape-1-by-car.html)
- [MY LITTLE CITY](https://skillplay.github.io/my-little-city.html)
- [SLINGSHOT FORTRESS](https://thequizzone.pages.dev/slingshot-fortress.html)
- [CATEGORY BASKETBALL](https://learnquester.pages.dev/category-basketball.html)
- [SNIPER MASTER](https://thequizzone.pages.dev/sniper-master.html)
- [CHICKEN WILD RUN](https://thequizzone.pages.dev/chicken-wild-run.html)
- [DROP ANIMALS](https://skillplay.github.io/drop-animals.html)
- [BLUE VS RED](https://thelearnquesters.pages.dev/blue-vs-red.html)
- [BACKFLIP MASTER](https://iskillplay.web.app/backflip-master.html)
- [BEAT THE ZOMBIES](https://iskillquest.pages.dev/beat-the-zombies.html)
- [BEAUTY WORLD AND FASHION STYLIST](https://thequizzone.pages.dev/beauty-world-and-fashion-stylist.html)
- [CATEGORY AVOID295](https://themindzone.pages.dev/category-avoid295.html)
- [SISYPHUS SIMULATOR](https://iskillplay.web.app/sisyphus-simulator.html)
- [PUSH THE FROG](https://learnquester.github.io/push-the-frog.html)
- [2 PLAYER BATTLE](https://learnquester.pages.dev/2-player-battle.html)
- [INDEX4](https://themindplay.pages.dev/index4.html)
- [CATEGORY MAKEUP](https://learnquester.pages.dev/category-makeup.html)
- [WORD SEARCH UNIVERSE 2](https://thequizzone.pages.dev/word-search-universe-2.html)
- [LOOP SURVIVORS ZOMBIE CITY](https://thelearnquester.web.app/loop-survivors-zombie-city.html)
- [WILD CASTLE TD GROW EMPIRE](https://thequizzone.pages.dev/wild-castle-td-grow-empire.html)
- [BLOWUP ATM](https://thelearnquesters.pages.dev/blowup-atm.html)
- [JUMP DASH](https://quizverses-9d2f2.web.app/jump-dash.html)
- [MAKE AMERICA GREAT AGAIN](https://skillplay.github.io/make-america-great-again.html)
