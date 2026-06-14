# --- data: command catalog (category|template|description) -------------------
# <token> placeholders are filled interactively; a trailing ? makes one
# optional (empty answer removes it). Same content as the docs/cheatsheet.
# Inspect any table with `mc-tui __dump catalog|items|enchantments|...`;
# extend with your own rows in ~/.config/mc-tui/catalog.local + items.local
# (same pipe-delimited format).

function catalog
    echo 'teleport|tp <player> <target>|teleport a player onto another player
teleport|tp <player> <x> <y> <z>|teleport to coordinates (~ relative, ^ local)
teleport|tp @a <player>|gather everyone onto one player
teleport|tp <player> ~ ~20 ~|lift 20 blocks straight up (unstuck)
teleport|execute in minecraft:the_nether run tp <player> <x> <y> <z>|cross-dimension tp (also: overworld, the_end)
teleport|spawnpoint <player> <x> <y> <z>|set a player respawn point
teleport|setworldspawn <x> <y> <z>|set the world spawn
give & items|give <player> <item> <count?>|give items — count defaults to 1
give & items|give @a <item> <count?>|give to every player online
give & items|give <player> enchanted_book[stored_enchantments={<enchantment>:<level>}]|a specific enchanted book (1.20.5+)
give & items|clear <player>|empty an entire inventory
give & items|clear <player> <item>|remove one item type only
god gear|give <player> netherite_sword[enchantments={sharpness:5,looting:3,sweeping_edge:3,fire_aspect:2,unbreaking:3,mending:1}]|god sword (netherite)
god gear|give <player> netherite_pickaxe[enchantments={efficiency:5,fortune:3,unbreaking:3,mending:1}]|god pickaxe (netherite) — swap fortune:3 for silk_touch:1 on a 2nd pick
god gear|give <player> netherite_axe[enchantments={efficiency:5,sharpness:5,unbreaking:3,mending:1}]|god axe (netherite)
god gear|give <player> netherite_shovel[enchantments={efficiency:5,silk_touch:1,unbreaking:3,mending:1}]|god shovel (netherite)
god gear|give <player> netherite_helmet[enchantments={protection:4,respiration:3,aqua_affinity:1,unbreaking:3,mending:1}]|god helmet (netherite)
god gear|give <player> netherite_chestplate[enchantments={protection:4,unbreaking:3,mending:1}]|god chestplate (netherite)
god gear|give <player> netherite_leggings[enchantments={protection:4,swift_sneak:3,unbreaking:3,mending:1}]|god leggings (netherite)
god gear|give <player> netherite_boots[enchantments={protection:4,feather_falling:4,depth_strider:3,soul_speed:3,unbreaking:3,mending:1}]|god boots (netherite)
god gear|give <player> diamond_sword[enchantments={sharpness:5,looting:3,sweeping_edge:3,fire_aspect:2,unbreaking:3,mending:1}]|god sword (diamond) — pre-netherite, same enchants
god gear|give <player> diamond_pickaxe[enchantments={efficiency:5,fortune:3,unbreaking:3,mending:1}]|god pickaxe (diamond) — swap fortune:3 for silk_touch:1 on a 2nd pick
god gear|give <player> diamond_axe[enchantments={efficiency:5,sharpness:5,unbreaking:3,mending:1}]|god axe (diamond)
god gear|give <player> diamond_shovel[enchantments={efficiency:5,silk_touch:1,unbreaking:3,mending:1}]|god shovel (diamond)
god gear|give <player> diamond_helmet[enchantments={protection:4,respiration:3,aqua_affinity:1,unbreaking:3,mending:1}]|god helmet (diamond)
god gear|give <player> diamond_chestplate[enchantments={protection:4,unbreaking:3,mending:1}]|god chestplate (diamond)
god gear|give <player> diamond_leggings[enchantments={protection:4,swift_sneak:3,unbreaking:3,mending:1}]|god leggings (diamond)
god gear|give <player> diamond_boots[enchantments={protection:4,feather_falling:4,depth_strider:3,soul_speed:3,unbreaking:3,mending:1}]|god boots (diamond)
god gear|give <player> bow[enchantments={power:5,infinity:1,flame:1,unbreaking:3}]|god bow — infinity excludes mending
god gear|give <player> crossbow[enchantments={quick_charge:3,multishot:1,unbreaking:3,mending:1}]|god crossbow — multishot excludes piercing
god gear|give <player> trident[enchantments={loyalty:3,channeling:1,impaling:5,unbreaking:3,mending:1}]|god trident — loyalty excludes riptide
god gear|give <player> mace[enchantments={density:5,wind_burst:3,fire_aspect:2,unbreaking:3,mending:1}]|god mace — density excludes breach
god gear|give <player> elytra[enchantments={unbreaking:3,mending:1}]|elytra (pair with firework_rocket 64)
effects & xp|enchant <player> <enchantment> <level?>|enchant the held item (survival-legal levels only)
effects & xp|effect give <player> <effect> <seconds?> <amplifier?>|amplifier 0 = level I; defaults: 30s, 0
effects & xp|effect give <player> <effect> infinite|lasts until cleared
effects & xp|effect clear <player>|remove all effects
effects & xp|xp add <player> <amount> levels|negative amount removes
effects & xp|xp add <player> <amount> points|points instead of levels
effects & xp|xp set <player> 0 points|zero the xp bar
effects & xp|xp query <player> levels|check a player level
gamemode|gamemode survival <player>|back to normal play
gamemode|gamemode creative <player>|build mode
gamemode|gamemode spectator <player>|fly through everything
gamemode|gamemode adventure <player>|no block breaking
gamemode|defaultgamemode survival|mode for new players
gamemode|difficulty hard|also: peaceful, easy, normal
gamemode|difficulty|query the current difficulty
time & weather|time set day|time marker — also: noon, night, midnight
time & weather|time set night|mob-farm o-clock
time & weather|time set <ticks>|0–24000; 24000 = one full day
time & weather|time add <ticks>|advance time
time & weather|time query time|current clock ticks (pre-26: time query daytime)
time & weather|time pause|freeze the day-night cycle (26.1+)
time & weather|time resume|let the clock run again (26.1+)
time & weather|weather clear <seconds?>|sunshine
time & weather|weather rain <seconds?>|rain
time & weather|weather thunder <seconds?>|thunderstorm (charged creepers...)
gamerules|gamerule keep_inventory true|no item loss on death (pre-26: keepInventory)
gamerules|gamerule keep_inventory false|back to vanilla deaths
gamerules|gamerule mob_griefing false|no creeper holes or enderman theft (pre-26: mobGriefing)
gamerules|gamerule advance_time false|freeze the time of day (pre-26: doDaylightCycle)
gamerules|gamerule advance_weather false|freeze the weather (pre-26: doWeatherCycle)
gamerules|gamerule spawn_mobs false|no natural hostile spawns (pre-26: doMobSpawning)
gamerules|gamerule fire_spread_radius_around_player <value>|fire spread limiter (pre-26: doFireTick)
gamerules|gamerule players_sleeping_percentage 1|one sleeper skips the night
gamerules|gamerule random_tick_speed <value>|crop growth speed — default 3
gamerules|gamerule respawn_radius <value>|spread of world-spawn respawns (pre-26: spawnRadius)
gamerules|gamerule <rule>|query the current value
gamerules|gamerule <rule> <value>|any other rule — 62 in 26.1 (help gamerule lists them)
building|setblock <x> <y> <z> <block>|place one block
building|fill <x> <y> <z> <x2> <y2> <z2> <block>|fill a region — max 32768 blocks
building|fill <x> <y> <z> <x2> <y2> <z2> air|clear a region
building|fill <x> <y> <z> <x2> <y2> <z2> <block> replace <block2>|replace only one block type
building|clone <x> <y> <z> <x2> <y2> <z2> <x3> <y3> <z3>|copy a region to a new corner
world & entities|summon <entity> ~ ~ ~|spawn an entity at your spot
world & entities|summon <entity> <x> <y> <z>|spawn an entity at coordinates
world & entities|summon lightning_bolt <x> <y> <z>|smite a spot
world & entities|kill @e[type=item]|clear dropped items (lag relief)
world & entities|kill @e[type=<entity>,distance=..<radius>]|kill nearby mobs of one type
world & entities|locate structure <structure>|coords of the nearest structure
world & entities|execute in minecraft:the_nether run locate structure <structure>|nether structures — plain locate over RCON searches the overworld
world & entities|locate biome <biome>|coords of the nearest biome
world & entities|seed|show the world seed
chat|list|who is online (great over RCON)
chat|say <message>|broadcast to all players
chat|msg <player> <message>|private message
chat|tellraw @a {"text":"<message>","color":"gold","bold":true}|formatted broadcast
chat|title @a title {"text":"<message>"}|big on-screen title
chat|title @a actionbar {"text":"<message>"}|message above the hotbar
moderation|kick <player> <reason?>|reason is optional
moderation|ban <player> <reason?>|ban by name
moderation|pardon <player>|undo a ban
moderation|ban-ip <ip>|ban by address
moderation|pardon-ip <ip>|undo an ip ban
moderation|banlist|show all bans
moderation|op <player>|grant operator
moderation|deop <player>|revoke operator
moderation|whitelist add <player>|onboard a friend
moderation|whitelist remove <player>|remove from whitelist
moderation|whitelist list|show the whitelist
moderation|whitelist on|enforce the whitelist
moderation|whitelist off|stop enforcing
moderation|whitelist reload|re-read whitelist.json
maintenance|list|who is online
maintenance|save-all flush|force-write the world, blocks until done
maintenance|save-off|pause autosave (do this around backups)
maintenance|save-on|resume autosave
maintenance|say Server restarting in 5 minutes|warn before restarts
maintenance|stop|graceful shutdown (saves first)
maintenance|reload|reload datapacks
maintenance|help <command?>|list commands or usage of one
railroad|give <player> powered_rail 64|powered (gold) rails — the boost rails
railroad|give <player> rail 64|plain rails — curves and corners
railroad|give <player> redstone_block 64|power source under powered rails (every 9)
railroad|give <player> detector_rail 16|redstone pulse when a cart passes
railroad|give <player> activator_rail 16|toggles cart behavior (eject, prime tnt)
railroad|give <player> minecart 8|ride the rails
railroad|give <player> chest_minecart 8|cargo on rails
railroad|give <player> stone_button 16|start a parked cart at a station
railroad|give <player> lever 8|toggle powered rails / switches
railroad|give <player> polished_andesite 64|deck — neutral grey (default)
railroad|give <player> polished_diorite 64|deck — light/white
railroad|give <player> polished_granite 64|deck — warm
railroad|give <player> stone_bricks 64|deck — classic
railroad|give <player> deepslate_bricks 64|deck — dark
railroad|give <player> glass 64|see-through guard walls
railroad|give <player> oak_fence 64|simple guard rail
railroad|give @a white_concrete 64|line color — swap white_ for any of the 16 colors'
    test -r $CFGDIR/catalog.local; and cat $CFGDIR/catalog.local
end

# --- data: items for <item>/<block> (group|id|pt-br name|note) ----------------
# pt-BR names come from the official game language file, so the picker can
# be searched in english or português (fzf matches the whole line).

function items
    echo 'netherite|netherite_sword|Espada de netherita|
netherite|netherite_pickaxe|Picareta de netherita|
netherite|netherite_axe|Machado de netherita|
netherite|netherite_shovel|Pá de netherita|
netherite|netherite_hoe|Enxada de netherita|
netherite|netherite_helmet|Capacete de netherita|
netherite|netherite_chestplate|Peitoral de netherita|
netherite|netherite_leggings|Calças de netherita|
netherite|netherite_boots|Botas de netherita|
diamond|diamond_sword|Espada de diamante|
diamond|diamond_pickaxe|Picareta de diamante|
diamond|diamond_axe|Machado de diamante|
diamond|diamond_shovel|Pá de diamante|
diamond|diamond_hoe|Enxada de diamante|
diamond|diamond_helmet|Capacete de diamante|
diamond|diamond_chestplate|Peitoral de diamante|
diamond|diamond_leggings|Calças de diamante|
diamond|diamond_boots|Botas de diamante|
iron|iron_sword|Espada de ferro|
iron|iron_pickaxe|Picareta de ferro|
iron|iron_axe|Machado de ferro|
iron|iron_shovel|Pá de ferro|
iron|iron_hoe|Enxada de ferro|
iron|iron_helmet|Capacete de ferro|
iron|iron_chestplate|Peitoral de ferro|
iron|iron_leggings|Calças de ferro|
iron|iron_boots|Botas de ferro|
ranged|bow|Arco|
ranged|crossbow|Besta|
ranged|arrow|Flecha|give 64
ranged|spectral_arrow|Flecha espectral|outlines targets
ranged|trident|Tridente|drowned drop only
ranged|mace|Clava|1.21 — pairs with wind_charge
ranged|wind_charge|Projétil de vento|launch yourself for mace smashes
ranged|shield|Escudo|blocks creeper blasts
food|golden_apple|Maçã dourada|absorption + regen
food|enchanted_golden_apple|Maçã dourada encantada|the real notch apple
food|golden_carrot|Cenoura dourada|best saturation per bite
food|cooked_beef|Filé|solid staple, give 64
food|cooked_porkchop|Costeleta de porco assada|same as beef
food|cooked_chicken|Frango assado|cheap staple
food|bread|Pão|early staple
food|baked_potato|Batata assada|farmable staple
food|pumpkin_pie|Torta de abóbora|no cooking needed
food|cake|Bolo|placeable party
food|honey_bottle|Frasco de mel|cures poison
food|milk_bucket|Balde de leite|clears all effects
mobility|elytra|Élitros|end-city loot
mobility|firework_rocket|Fogo de artifício|give 64 — elytra fuel
mobility|ender_pearl|Pérola de ender|give 16
mobility|saddle|Sela|ride pigs, horses, striders
mobility|minecart|Carrinho de mina|
mobility|oak_boat|Bote de carvalho|
survival|totem_of_undying|Totem da imortalidade|cheats death from offhand
survival|water_bucket|Balde de água|the universal mlg answer
survival|lava_bucket|Balde de lava|fuel + cast obsidian
survival|bucket|Balde|
survival|flint_and_steel|Pederneira|portals + fires
survival|torch|Tocha|give 64
survival|soul_torch|Tocha das almas|scares piglins
survival|lantern|Lampião|brighter, hangable
survival|campfire|Fogueira|cooks without fuel, no aggro
survival|ladder|Escada de mão|
survival|scaffolding|Andaime|safe up-and-down
utility|compass|Bússola|points to world spawn
utility|recovery_compass|Bússola de retomada|points to your last death
utility|clock|Relógio|
utility|map|Mapa em branco|empty map — fill by holding
utility|spyglass|Luneta|
utility|fishing_rod|Vara de pesca|
utility|shears|Tesoura|wool, leaves, vines
utility|brush|Pincel|archaeology
utility|lead|Laço|walk your animals
utility|name_tag|Etiqueta|stops despawning, names pets
utility|ender_eye|Olho de ender|find the stronghold
utility|experience_bottle|Frasco de experiência|give 64 — bottled xp
utility|bone_meal|Farinha de osso|instant growth, give 64
utility|tnt|Dinamite|careful now
utility|item_frame|Moldura|
utility|armor_stand|Suporte de armaduras|
storage|chest|Baú|
storage|barrel|Barril|chest that opens under blocks
storage|ender_chest|Baú de ender|per-player private storage
storage|shulker_box|Caixa de shulker|portable chest, keeps contents
storage|bundle|Trouxa|pocket for odd stacks
storage|hopper|Funil|moves items between containers
brewing|brewing_stand|Suporte de poções|
brewing|blaze_powder|Pó de blaze|brewing fuel
brewing|nether_wart|Fungo do Nether|base of almost every potion
brewing|glass_bottle|Frasco de vidro|
brewing|glistering_melon_slice|Fatia de melancia reluzente|healing potions
brewing|magma_cream|Creme de magma|fire resistance potions
brewing|ghast_tear|Lágrima de ghast|regeneration potions
brewing|phantom_membrane|Membrana de phantom|slow falling potions
brewing|fermented_spider_eye|Olho de aranha fermentado|corrupts potions (inverts)
brewing|dragon_breath|Bafo do dragão|lingering potions
brewing|potion[potion_contents={potion:"minecraft:strong_healing"}]|Poção de cura|Healing II bottle
brewing|potion[potion_contents={potion:"minecraft:long_fire_resistance"}]|Poção de resistência ao fogo|8-min fire resistance
brewing|potion[potion_contents={potion:"minecraft:long_night_vision"}]|Poção de visão noturna|8-min night vision
brewing|splash_potion[potion_contents={potion:"minecraft:strong_harming"}]|Poção arremessável de dano|Harming II splash
brewing|lingering_potion[potion_contents={potion:"minecraft:long_regeneration"}]|Poção prolongada de regeneração|regen cloud
books|enchanted_book[stored_enchantments={mending:1}]|Livro encantado (Remendo)|the book everyone wants
books|enchanted_book[stored_enchantments={efficiency:5}]|Livro encantado (Eficiência)|
books|enchanted_book[stored_enchantments={fortune:3}]|Livro encantado (Fortuna)|
books|enchanted_book[stored_enchantments={silk_touch:1}]|Livro encantado (Toque Suave)|
books|enchanted_book[stored_enchantments={sharpness:5}]|Livro encantado (Afiação)|
books|enchanted_book[stored_enchantments={looting:3}]|Livro encantado (Saque)|
books|enchanted_book[stored_enchantments={protection:4}]|Livro encantado (Proteção)|
books|enchanted_book[stored_enchantments={feather_falling:4}]|Livro encantado (Peso-pena)|
books|enchanted_book[stored_enchantments={unbreaking:3}]|Livro encantado (Inquebrável)|
books|enchanted_book[stored_enchantments={infinity:1}]|Livro encantado (Infinidade)|
books|book|Livro|
books|writable_book|Livro e pena|book and quill
workshop|crafting_table|Bancada de trabalho|
workshop|furnace|Fornalha|
workshop|blast_furnace|Alto-forno|ores 2x speed, armorer job block
workshop|smoker|Defumador|food 2x speed
workshop|anvil|Bigorna|
workshop|grindstone|Rebolo|disenchant + weaponsmith job block
workshop|enchanting_table|Mesa de encantamentos|
workshop|bookshelf|Estante de livros|15 around the table = lvl 30
workshop|lectern|Atril|librarian job block
workshop|smithing_table|Bancada de ferraria|netherite upgrades, toolsmith
workshop|cartography_table|Bancada de cartografia|
workshop|loom|Tear|banner patterns
workshop|stonecutter|Cortador de pedras|precise stone recipes
workshop|fletching_table|Bancada de arco e flecha|fletcher job block
workshop|composter|Composteira|excess crops to bone meal
workshop|bell|Sino|raid alarm, villager magnet
blocks|obsidian|Obsidiana|portals
blocks|crying_obsidian|Obsidiana chorona|respawn anchors
blocks|respawn_anchor|Âncora de renascimento|nether respawn (charge with glowstone)
blocks|lodestone|Magnetita|bind compasses anywhere
blocks|glowstone|Pedra luminosa|
blocks|sea_lantern|Lanterna marinha|
blocks|shroomlight|Cogubrilho|
blocks|glass|Vidro|
blocks|stone|Pedra|
blocks|cobblestone|Pedregulho|
blocks|deepslate|Ardosiabissal|
blocks|dirt|Terra|
blocks|grass_block|Bloco de grama|
blocks|sand|Areia|
blocks|gravel|Cascalho|
blocks|oak_log|Tronco de carvalho|
blocks|oak_planks|Tábuas de carvalho|
blocks|white_wool|Lã branca|
blocks|sponge|Esponja|drink a lake
blocks|slime_block|Bloco de slime|bouncy, sticky redstone
blocks|honey_block|Bloco de mel|slower slime block, no jump
blocks|blue_ice|Gelo azul|boat highways
blocks|packed_ice|Gelo compactado|cheaper highways
blocks|soul_sand|Areia das almas|bubble elevators up
blocks|magma_block|Bloco de magma|bubble elevators down
blocks|beacon|Sinalizador|haste II for the whole base
blocks|conduit|Aqueduto|underwater beacon
build|stone_bricks|Tijolos de pedra|classic castle wall
build|mossy_stone_bricks|Tijolos de pedra musgosos|aged, overgrown look
build|cracked_stone_bricks|Tijolos de pedra rachados|ruined-castle accent
build|chiseled_stone_bricks|Tijolos de pedra entalhados|decorative inlay
build|smooth_stone|Pedra lisa|clean grey, pairs with stone slabs
build|polished_andesite|Andesito polido|smooth neutral grey
build|polished_diorite|Diorito polido|light/white stone
build|polished_granite|Granito polido|warm pink-brown stone
build|bricks|Tijolos|red clay — cozy homes
build|mossy_cobblestone|Pedregulho musgoso|rustic walls and paths
build|deepslate_bricks|Tijolos de ardósia|dark grey, dramatic
build|deepslate_tiles|Ladrilhos de ardósia|fine dark tiling
build|polished_deepslate|Ardósia polida|smooth charcoal
build|cobbled_deepslate|Ardósia lascada|raw dark stone
build|polished_tuff|Tufo polido|soft greenish-grey (1.21)
build|tuff_bricks|Tijolos de tufo|muted brick variant (1.21)
build|calcite|Calcita|bright off-white
build|sandstone|Arenito|desert builds
build|smooth_sandstone|Arenito liso|clean sand walls
build|cut_sandstone|Arenito cortado|paneled sand
build|red_sandstone|Arenito vermelho|mesa/warm builds
build|quartz_block|Bloco de quartzo|pure white pillars and trim
build|smooth_quartz|Quartzo liso|seamless white
build|chiseled_quartz_block|Bloco de quartzo entalhado|white detail block
build|quartz_bricks|Tijolos de quartzo|white brickwork
build|prismarine_bricks|Tijolos de prismarinho|teal — ocean keeps
build|dark_prismarine|Prismarinho escuro|deep teal accent
build|blackstone|Pedra negra|black nether stone
build|polished_blackstone|Pedra negra polida|smooth black
build|polished_blackstone_bricks|Tijolos de pedra negra polida|black castle brick
build|nether_bricks|Tijolos do Nether|dark red-brown, fortress
build|red_nether_bricks|Tijolos vermelhos do Nether|deep crimson
build|end_stone_bricks|Tijolos da pedra do End|pale yellow, end builds
build|purpur_block|Bloco de púrpura|purple end-city block
roof|stone_brick_stairs|Escadas de tijolos de pedra|rooftop + steps
roof|stone_brick_slab|Laje de tijolos de pedra|thin roofs, ledges
roof|mossy_stone_brick_stairs|Escadas de tijolos de pedra musgosos|aged roof
roof|brick_stairs|Escadas de tijolos|red-roof cottages
roof|brick_slab|Laje de tijolos|red roof tiles
roof|smooth_stone_slab|Laje de pedra lisa|clean grey ledge
roof|polished_andesite_stairs|Escadas de andesito polido|grey roof + steps
roof|polished_andesite_slab|Laje de andesito polido|grey ledge
roof|polished_diorite_stairs|Escadas de diorito polido|white roof + steps
roof|polished_diorite_slab|Laje de diorito polido|white ledge
roof|polished_granite_stairs|Escadas de granito polido|warm roof + steps
roof|polished_granite_slab|Laje de granito polido|warm ledge
roof|deepslate_brick_stairs|Escadas de tijolos de ardósia|dark roof + steps
roof|deepslate_brick_slab|Laje de tijolos de ardósia|dark ledge
roof|polished_deepslate_stairs|Escadas de ardósia polida|charcoal roof
roof|sandstone_stairs|Escadas de arenito|desert roof + steps
roof|smooth_sandstone_slab|Laje de arenito liso|sand ledge
roof|quartz_stairs|Escadas de quartzo|white roof + steps
roof|smooth_quartz_stairs|Escadas de quartzo liso|seamless white roof
roof|nether_brick_stairs|Escadas de tijolos do Nether|dark fortress roof
roof|blackstone_stairs|Escadas de pedra negra|black roof + steps
roof|polished_blackstone_brick_stairs|Escadas de tijolos de pedra negra polida|black castle roof
roof|prismarine_brick_stairs|Escadas de tijolos de prismarinho|teal roof
roof|dark_prismarine_stairs|Escadas de prismarinho escuro|deep teal roof
roof|purpur_stairs|Escadas de púrpura|purple roof + steps
wall|stone_brick_wall|Muro de tijolos de pedra|castle battlements
wall|cobblestone_wall|Muro de pedregulho|rustic fences
wall|mossy_stone_brick_wall|Muro de tijolos de pedra musgosos|aged battlements
wall|brick_wall|Muro de tijolos|red-brick fences
wall|deepslate_brick_wall|Muro de tijolos de ardósia|dark battlements
wall|polished_blackstone_brick_wall|Muro de tijolos de pedra negra polida|black battlements
wall|sandstone_wall|Muro de arenito|desert walls
wall|nether_brick_wall|Muro de tijolos do Nether|fortress walls
redstone|redstone|Pó de redstone|
redstone|redstone_torch|Tocha de redstone|
redstone|redstone_block|Bloco de redstone|
redstone|repeater|Repetidor de redstone|
redstone|comparator|Comparador de redstone|
redstone|observer|Observador|sees block updates
redstone|piston|Pistão|
redstone|sticky_piston|Pistão grudento|
redstone|dispenser|Ejetor|shoots items
redstone|dropper|Liberador|drops items
redstone|lever|Alavanca|
redstone|stone_button|Botão de pedra|
redstone|oak_pressure_plate|Placa de pressão de carvalho|
redstone|daylight_detector|Detector de luz solar|
redstone|target|Alvo|redstone from arrows
redstone|note_block|Bloco musical|
redstone|rail|Trilho|
redstone|powered_rail|Trilho elétrico|needs gold
redstone|detector_rail|Trilho detector|
redstone|activator_rail|Trilho ativador|
redstone|chest_minecart|Carrinho de mina com baú|
redstone|hopper_minecart|Carrinho de mina com funil|item pickup on rails
redstone|tnt_minecart|Carrinho de mina com dinamite|why though
resources|diamond|Diamante|
resources|emerald|Esmeralda|villager currency
resources|iron_ingot|Barra de ferro|
resources|gold_ingot|Barra de ouro|
resources|copper_ingot|Barra de cobre|
resources|netherite_ingot|Barra de netherita|
resources|netherite_scrap|Fragmentos de netherita|
resources|ancient_debris|Detritos ancestrais|
resources|netherite_upgrade_smithing_template|Molde de ferraria|needed per netherite upgrade
resources|coal|Carvão|
resources|charcoal|Carvão vegetal|renewable coal
resources|lapis_lazuli|Lápis-lazúli|enchanting fuel
resources|quartz|Quartzo do Nether|
resources|amethyst_shard|Fragmento de ametista|
resources|echo_shard|Fragmento de eco|recovery compasses
resources|nether_star|Estrela do Nether|beacons
resources|heart_of_the_sea|Coração do mar|conduits
resources|nautilus_shell|Concha de náutilo|conduits
resources|shulker_shell|Casco de shulker|shulker boxes
resources|string|Linha|
resources|leather|Couro|bookshelves need it
resources|feather|Pena|arrows
resources|flint|Sílex|arrows + flint and steel
resources|gunpowder|Pólvora|rockets + tnt
resources|bone|Osso|
resources|blaze_rod|Vara de blaze|brewing + eyes of ender
resources|paper|Papel|
resources|slime_ball|Bola de slime|sticky pistons, leads
resources|honeycomb|Favo de mel|wax copper, hives
eggs|villager_spawn_egg|Ovo gerador de aldeão|instant neighbor
eggs|horse_spawn_egg|Ovo gerador de cavalo|
eggs|wolf_spawn_egg|Ovo gerador de lobo|
eggs|cat_spawn_egg|Ovo gerador de gato|creeper repellent
eggs|sheep_spawn_egg|Ovo gerador de ovelha|
eggs|axolotl_spawn_egg|Ovo gerador de axolote|
eggs|allay_spawn_egg|Ovo gerador de allay|item-fetching helper'
    test -r $CFGDIR/items.local; and cat $CFGDIR/items.local
end

# --- data: small pickers (id|note) -------------------------------------------

function data_enchantments
    echo 'sharpness|Afiação — V — melee damage (sword, axe)
smite|Julgamento — V — extra vs undead (excludes sharpness)
bane_of_arthropods|Ruína dos Artrópodes — V — extra vs spiders (excludes sharpness)
looting|Saque — III — more mob drops (sword)
sweeping_edge|Alcance — III — sweep damage (sword)
fire_aspect|Aspecto Flamejante — II — sets targets on fire
knockback|Repulsão — II
efficiency|Eficiência — V — mining speed
fortune|Fortuna — III — more ore drops (excludes silk_touch)
silk_touch|Toque Suave — I — blocks drop themselves (excludes fortune)
unbreaking|Inquebrável — III — durability
mending|Remendo — I — repairs with xp (excludes infinity on bows)
protection|Proteção — IV — armor, the default pick
fire_protection|Proteção contra Fogo — IV (excludes other protections)
blast_protection|Proteção contra Explosões — IV (excludes other protections)
projectile_protection|Proteção contra Projéteis — IV (excludes other protections)
feather_falling|Peso-pena — IV — boots
respiration|Respiração — III — helmet
aqua_affinity|Afinidade Aquática — I — helmet, mine underwater
depth_strider|Passos Profundos — III — boots (excludes frost_walker)
frost_walker|Passos Gelados — II — boots, walk on water
soul_speed|Velocidade das Almas — III — boots, fast on soul sand
swift_sneak|Passos Furtivos — III — leggings, ancient city loot
thorns|Espinhos — III — damages attackers
power|Força — V — bow damage
punch|Impacto — II — bow knockback
flame|Chama — I — fire arrows
infinity|Infinidade — I — bow (excludes mending)
quick_charge|Carga Rápida — III — crossbow
multishot|Rajada — I — crossbow (excludes piercing)
piercing|Perfuração — IV — crossbow (excludes multishot)
loyalty|Lealdade — III — trident returns (excludes riptide)
channeling|Condutividade — I — trident lightning in storms
riptide|Correnteza — III — trident travel (excludes loyalty)
impaling|Penetração — V — trident damage
density|Densidade — V — mace damage (excludes breach)
breach|Ruptura — IV — mace armor-piercing (excludes density)
wind_burst|Rajada de Vento — III — mace bounce
luck_of_the_sea|Sorte do Mar — III — fishing rod
lure|Isca — III — fishing rod'
end

function data_effects
    echo 'speed|Velocidade
slowness|Lentidão
haste|Pressa — mine faster
mining_fatigue|Exaustão
strength|Força
instant_health|Vida Instantânea
instant_damage|Dano Instantâneo
jump_boost|Supersalto
regeneration|Regeneração
resistance|Resistência
fire_resistance|Resistência ao Fogo — nether essential
water_breathing|Respiração Aquática
invisibility|Invisibilidade
night_vision|Visão Noturna
blindness|Cegueira
hunger|Fome
weakness|Fraqueza — zombie villager cures
poison|Veneno
wither|Decomposição
health_boost|Vida Extra
absorption|Absorção
saturation|Saturação
glowing|Brilho — outline through walls
levitation|Levitação
slow_falling|Queda Lenta
luck|Sorte
conduit_power|Proteção do Mar
dolphins_grace|Dádiva Marinha — swim fast
darkness|Escuridão
hero_of_the_village|Herói da Vila — trade discounts'
end

function data_entities
    echo 'zombie|Zumbi
skeleton|Esqueleto
creeper|Creeper
spider|Aranha
enderman|Enderman
witch|Bruxa
slime|Slime
drowned|Afogado
husk|Zumbi-múmia
stray|Errante
phantom|Phantom
blaze|Blaze
ghast|Ghast
magma_cube|Cubo de magma
wither_skeleton|Esqueleto Wither
piglin|Piglin
zombified_piglin|Piglin-zumbi
hoglin|Hoglin
warden|Defensor — run
villager|Aldeão
wandering_trader|Vendedor ambulante
iron_golem|Golem de ferro
snow_golem|Golem de neve
horse|Cavalo
donkey|Burro
wolf|Lobo
cat|Gato
cow|Vaca
pig|Porco
sheep|Ovelha
chicken|Galinha
axolotl|Axolote
allay|Allay
armor_stand|Suporte de armaduras
lightning_bolt|Relâmpago — smite
wither|Wither — boss — are you sure
ender_dragon|Dragão Ender — boss — are you REALLY sure'
end

function data_structures
    echo '#minecraft:village|any village (tag)
village_plains|
village_desert|
village_savanna|
village_snowy|
village_taiga|
pillager_outpost|
mineshaft|
desert_pyramid|
jungle_pyramid|
igloo|
swamp_hut|
monument|ocean monument
mansion|woodland mansion
shipwreck|
buried_treasure|
ruined_portal|
ancient_city|deep dark
trial_chambers|1.21+
trail_ruins|
stronghold|end portal
fortress|nether — locate via execute in the_nether
bastion_remnant|nether — piglin loot
end_city|the end — elytra'
end

function data_biomes
    echo 'plains|Planícies
desert|Deserto
jungle|Selva
bamboo_jungle|Selva de bambu
swamp|Pântano
mangrove_swamp|Manguezal
cherry_grove|Cerejal
dark_forest|Floresta escura
pale_garden|Jardim pálido — 1.21.4
ice_spikes|Picos de gelo
frozen_peaks|Picos congelados
badlands|Terras áridas
mushroom_fields|Campos de cogumelos — no hostile spawns
deep_dark|Profundezas sombrias
lush_caves|Cavernas verdejantes
dripstone_caves|Cavernas de espeleotemas'
end

