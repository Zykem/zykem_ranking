
<h1>Installation</h1>

1. Install Files
2. Drag and Drop them to your resources Folder
3. Add `ensure zykem_ranking` to your server.cfg and type ```refresh\nrestart zykem_ranking``` in your server console

<h1>Features</h1>
<ul>
    <li>ESX-Based</b></li>
    <li>Highly Configurable</li>
    <li>Locales [ Polish and English ]</li>
    <li>Optimized</li>
    <li>Ranking of playtime, kills, money, deaths</li>
    <li>Inbuilt Tokenizer (every player has his own token and gets a new one after he triggers the kill/death event</li>
</ul>

# Configuration
```lua
config.main = {

    locale = "en", -- "en" or "pl"
    playTimeRanking = true,
    moneyRanking = true,
    killsRanking = true,
    deathsRanking = true,
    npcKills = true, -- if player kills an npc, it adds up to the normal kill count. ( can be abused )
    token_prefixes = {"zykem_ranking_", "i_love_my_dad_", "u_have_no_parents_", "get_on_my_lvl_", "my_parents_abuse_me_"} -- random item of this table gets assigned every time a new token is generated

}
```


<h1>Preview</h1>
<ul>
  <li>https://www.youtube.com/watch?v=cZmqnoTBrcE&feature=youtu.be</li>
</ul>

<h1>Todo - Open for Suggestions</h1>
Discord: zykem#0643

