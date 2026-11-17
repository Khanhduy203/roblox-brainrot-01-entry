-- Brainrot Isles: the cast.
-- One job: describe every brainrot, rarity and mutation, and roll new ones.
-- The spawner reads this to decide what walks down the belt, the factory
-- reads it to build the model, and the economy reads it to price a sale.

local BrainrotCatalog = {}

BrainrotCatalog.RARITY_ORDER = {
	"Common",
	"Rare",
	"Epic",
	"Legendary",
	"Mythic",
	"BrainrotGod",
	"Secret",
}

BrainrotCatalog.RARITIES = {
	Common = { Weight = 45, Color = Color3.fromRGB(170, 170, 170) },
	Rare = { Weight = 25, Color = Color3.fromRGB(80, 170, 255) },
	Epic = { Weight = 15, Color = Color3.fromRGB(175, 95, 255) },
	Legendary = { Weight = 9, Color = Color3.fromRGB(255, 190, 40) },
	Mythic = { Weight = 4, Color = Color3.fromRGB(255, 80, 120) },
	BrainrotGod = { Weight = 1.7, Color = Color3.fromRGB(255, 240, 120) },
	Secret = { Weight = 0.3, Color = Color3.fromRGB(45, 230, 200) },
}

BrainrotCatalog.MUTATIONS = {
	Normal = { Multiplier = 1, Chance = 88, Color = Color3.fromRGB(255, 255, 255) },
	Golden = { Multiplier = 2, Chance = 7, Color = Color3.fromRGB(255, 215, 0) },
	Diamond = { Multiplier = 5, Chance = 3.5, Color = Color3.fromRGB(120, 220, 255) },
	Rainbow = { Multiplier = 10, Chance = 1.5, Color = Color3.fromRGB(255, 120, 220) },
}

-- Id, Name, Rarity, Cost, Income ($/s), Body color, Head color, Scale, Blurb.
BrainrotCatalog.BRAINROTS = {
	{ Id = "toaster_toad", Name = "Toaster Toad", Rarity = "Common", Cost = 25, Income = 1, Body = Color3.fromRGB(200, 160, 90), Head = Color3.fromRGB(230, 200, 120), Scale = 1.0, Blurb = "Croaks in toast. Pops up when warm." },
	{ Id = "sock_goblin", Name = "Sock Goblin", Rarity = "Common", Cost = 50, Income = 2, Body = Color3.fromRGB(120, 140, 200), Head = Color3.fromRGB(160, 180, 230), Scale = 1.0, Blurb = "Steals one sock from every pair." },
	{ Id = "pickle_wizard", Name = "Pickle Wizard", Rarity = "Rare", Cost = 150, Income = 6, Body = Color3.fromRGB(90, 170, 80), Head = Color3.fromRGB(140, 210, 110), Scale = 1.1, Blurb = "Casts brine. Nobody asked him to." },
	{ Id = "chairman_meow", Name = "Chairman Meow", Rarity = "Rare", Cost = 300, Income = 10, Body = Color3.fromRGB(240, 150, 60), Head = Color3.fromRGB(250, 200, 120), Scale = 1.1, Blurb = "Runs the meeting. Sleeps through it." },
	{ Id = "dj_spaghetti", Name = "DJ Spaghetti", Rarity = "Epic", Cost = 800, Income = 25, Body = Color3.fromRGB(230, 210, 140), Head = Color3.fromRGB(255, 120, 120), Scale = 1.2, Blurb = "Drops beats. Drops noodles. Same thing." },
	{ Id = "grandma_rocket", Name = "Grandma Rocket", Rarity = "Epic", Cost = 1500, Income = 40, Body = Color3.fromRGB(180, 120, 200), Head = Color3.fromRGB(220, 220, 220), Scale = 1.2, Blurb = "Bakes cookies at Mach 3." },
	{ Id = "sir_bananasworth", Name = "Sir Bananasworth", Rarity = "Legendary", Cost = 4000, Income = 90, Body = Color3.fromRGB(255, 220, 60), Head = Color3.fromRGB(255, 240, 150), Scale = 1.3, Blurb = "Knighted for peeling. Never slips." },
	{ Id = "tax_manatee", Name = "Tax Manatee", Rarity = "Legendary", Cost = 7000, Income = 150, Body = Color3.fromRGB(130, 160, 190), Head = Color3.fromRGB(170, 200, 220), Scale = 1.4, Blurb = "Slow, gentle, and taking 30 percent." },
	{ Id = "captain_noodlebeard", Name = "Captain Noodlebeard", Rarity = "Mythic", Cost = 15000, Income = 350, Body = Color3.fromRGB(200, 120, 60), Head = Color3.fromRGB(240, 190, 90), Scale = 1.5, Blurb = "Sails the soup seas. Fears no fork." },
	{ Id = "quantum_quokka", Name = "Quantum Quokka", Rarity = "Mythic", Cost = 25000, Income = 600, Body = Color3.fromRGB(150, 110, 80), Head = Color3.fromRGB(200, 160, 120), Scale = 1.5, Blurb = "Happy in two places at once." },
	{ Id = "el_grande_burrito", Name = "El Grande Burrito", Rarity = "BrainrotGod", Cost = 60000, Income = 1500, Body = Color3.fromRGB(190, 140, 70), Head = Color3.fromRGB(120, 200, 90), Scale = 1.7, Blurb = "Wrapped in legend. Extra guac." },
	{ Id = "infinite_mime", Name = "Infinite Mime", Rarity = "BrainrotGod", Cost = 120000, Income = 3000, Body = Color3.fromRGB(240, 240, 240), Head = Color3.fromRGB(60, 60, 60), Scale = 1.7, Blurb = "Trapped in a box of his own making." },
	{ Id = "glorbo_prime", Name = "Glorbo Prime", Rarity = "Secret", Cost = 300000, Income = 10000, Body = Color3.fromRGB(45, 230, 200), Head = Color3.fromRGB(255, 240, 120), Scale = 2.0, Blurb = "Nobody knows what Glorbo is. Glorbo knows." },
}

function BrainrotCatalog.getById(id)
	for _, def in ipairs(BrainrotCatalog.BRAINROTS) do
		if def.Id == id then
			return def
		end
	end
	return nil
end

function BrainrotCatalog.rollRarity()
	local total = 0
	for _, name in ipairs(BrainrotCatalog.RARITY_ORDER) do
		total = total + BrainrotCatalog.RARITIES[name].Weight
	end
	local roll = math.random() * total
	for _, name in ipairs(BrainrotCatalog.RARITY_ORDER) do
		roll = roll - BrainrotCatalog.RARITIES[name].Weight
		if roll <= 0 then
			return name
		end
	end
	return "Common"
end

function BrainrotCatalog.rollMutation()
	local roll = math.random() * 100
	local acc = 0
	for _, name in ipairs({ "Normal", "Golden", "Diamond", "Rainbow" }) do
		acc = acc + BrainrotCatalog.MUTATIONS[name].Chance
		if roll <= acc then
			return name
		end
	end
	return "Normal"
end

function BrainrotCatalog.pickForRarity(rarity)
	local pool = {}
	for _, def in ipairs(BrainrotCatalog.BRAINROTS) do
		if def.Rarity == rarity then
			table.insert(pool, def)
		end
	end
	if #pool == 0 then
		return BrainrotCatalog.BRAINROTS[1]
	end
	return pool[math.random(1, #pool)]
end

function BrainrotCatalog.incomeOf(def, mutationName)
	local mut = BrainrotCatalog.MUTATIONS[mutationName] or BrainrotCatalog.MUTATIONS.Normal
	return def.Income * mut.Multiplier
end

function BrainrotCatalog.priceOf(def, mutationName)
	local mut = BrainrotCatalog.MUTATIONS[mutationName] or BrainrotCatalog.MUTATIONS.Normal
	return math.floor(def.Cost * mut.Multiplier + 0.5)
end

function BrainrotCatalog.rarityColor(rarity)
	local entry = BrainrotCatalog.RARITIES[rarity]
	if entry then
		return entry.Color
	end
	return Color3.fromRGB(255, 255, 255)
end

function BrainrotCatalog.mutationColor(mutationName)
	local entry = BrainrotCatalog.MUTATIONS[mutationName]
	if entry then
		return entry.Color
	end
	return Color3.fromRGB(255, 255, 255)
end

function BrainrotCatalog.displayName(def, mutationName)
	if mutationName == "Normal" or mutationName == nil then
		return def.Name
	end
	return mutationName .. " " .. def.Name
end

return BrainrotCatalog
