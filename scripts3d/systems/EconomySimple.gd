extends BaseSystemSimple

class_name EconomySimple

class PriceData:
	var base_price: float
	var current_price: float
	var demand: float
	var supply: float
	func _init(p_base: float, p_demand: float = 1.0, p_supply: float = 1.0) -> void:
		base_price = p_base
		current_price = p_base
		demand = p_demand
		supply = p_supply

var prices: Dictionary = {}

signal price_changed(item: String, new_price: float)
signal inflation_occurred(rate: float)
signal deflation_occurred(rate: float)
signal market_trend_changed(trend: String)
signal scarcity_alert(item: String, level: float)

func _ready() -> void:
	set_state("global_inflation", 0.0)
	set_state("market_stability", 1.0)
	set_state("price_history", {})
	set_state("market_trends", {})
	set_state("scarcity_levels", {})
	set_state("demand_supply_history", [])
	set_state("inflation_deflation_history", [])
	set_state("market_trend_history", [])
	set_state("economy_statistics", {})
	_initialize_prices()

func _initialize_prices() -> void:
	prices["health_potion"] = PriceData.new(25.0)
	prices["mana_potion"] = PriceData.new(20.0)
	prices["sword"] = PriceData.new(150.0)
	prices["armor"] = PriceData.new(200.0)
	prices["bread"] = PriceData.new(5.0)
	prices["horse"] = PriceData.new(500.0)
	prices["gem"] = PriceData.new(100.0)

func update_prices() -> void:
	var inflation = get_state("global_inflation", 0.0)
	inflation += randf_range(-0.01, 0.02)
	inflation = clampf(inflation, -0.2, 0.3)
	set_state("global_inflation", inflation)

	for item_name in prices.keys():
		var price_data = prices[item_name]
		var market_factor = 1.0 + inflation
		market_factor *= (price_data.demand / price_data.supply)
		var new_price = price_data.base_price * clampf(market_factor, 0.5, 2.0)

		if absf(new_price - price_data.current_price) > 0.1:
			price_data.current_price = new_price
			price_changed.emit(item_name, new_price)
			emit_event("price_changed", item_name)

	_record_demand_supply_state()
	if inflation > 0.1:
		_record_inflation_deflation(inflation, true)
		inflation_occurred.emit(inflation)
		emit_event("inflation", inflation)
	elif inflation < -0.1:
		_record_inflation_deflation(absf(inflation), false)
		deflation_occurred.emit(absf(inflation))
		emit_event("deflation", inflation)

func set_demand(item: String, demand: float) -> void:
	if item in prices:
		prices[item].demand = clampf(demand, 0.1, 5.0)
		_record_demand_supply_state()
		emit_event("demand_changed", item)

func set_supply(item: String, supply: float) -> void:
	if item in prices:
		prices[item].supply = clampf(supply, 0.1, 5.0)
		_record_demand_supply_state()
		emit_event("supply_changed", item)

func get_price(item: String) -> float:
	if item in prices:
		return prices[item].current_price
	return 0.0

func get_base_price(item: String) -> float:
	if item in prices:
		return prices[item].base_price
	return 0.0

func get_all_prices() -> Dictionary:
	var result = {}
	for item in prices.keys():
		result[item] = prices[item].current_price
	return result

func get_inflation_rate() -> float:
	return get_state("global_inflation", 0.0)

func get_economy_text() -> String:
	var inflation = get_inflation_rate()
	var text = "Economy\nInflation: %.1f%%\n" % (inflation * 100.0)
	text += "Prices:\n"
	for item in prices.keys():
		var current = prices[item].current_price
		var base = prices[item].base_price
		var change = ((current - base) / base) * 100.0
		text += "%s: %.0f (%.0f%%)\n" % [item.capitalize(), current, change]
	return text

func record_price_history(item: String) -> void:
	var history = get_state("price_history", {})
	if item not in history:
		history[item] = []
	if item in prices:
		history[item].append({"price": prices[item].current_price, "time": Time.get_ticks_msec()})
		if history[item].size() > 100:
			history[item].pop_front()
	set_state("price_history", history)

func set_market_trend(trend_type: String) -> void:
	var trends = get_state("market_trends", {})
	var current = trends.get("active_trend", "stable")
	if current != trend_type:
		trends["active_trend"] = trend_type
		trends["trend_changed_at"] = Time.get_ticks_msec()
		set_state("market_trends", trends)
		_record_market_trend(trend_type)
		market_trend_changed.emit(trend_type)
		emit_event("trend_changed", trend_type)

func get_market_trend() -> String:
	var trends = get_state("market_trends", {})
	return trends.get("active_trend", "stable")

func set_scarcity_level(item: String, level: float) -> void:
	var scarcity = get_state("scarcity_levels", {})
	level = clampf(level, 0.0, 1.0)
	scarcity[item] = level
	set_state("scarcity_levels", scarcity)
	if level > 0.7:
		scarcity_alert.emit(item, level)
		emit_event("scarcity_high", item)

func get_scarcity_level(item: String) -> float:
	var scarcity = get_state("scarcity_levels", {})
	return scarcity.get(item, 0.0)

func _record_demand_supply_state() -> void:
	var history = get_state("demand_supply_history", [])
	var state = {}
	for item in prices:
		state[item] = {"demand": prices[item].demand, "supply": prices[item].supply}
	history.append({"state": state, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("demand_supply_history", history)

func _record_inflation_deflation(rate: float, is_inflation: bool) -> void:
	var history = get_state("inflation_deflation_history", [])
	history.append({"rate": rate, "is_inflation": is_inflation, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("inflation_deflation_history", history)

func _record_market_trend(trend: String) -> void:
	var history = get_state("market_trend_history", [])
	history.append({"trend": trend, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("market_trend_history", history)

func update_economy_statistics() -> void:
	var stats = get_state("economy_statistics", {})
	var inflation = get_state("global_inflation", 0.0)
	var stable = get_state("market_stability", 1.0)
	stats["global_inflation"] = inflation
	stats["market_stability"] = stable
	stats["price_changes_tracked"] = 0
	for item in prices:
		var history = get_state("price_history", {})
		if item in history:
			stats["price_changes_tracked"] += history[item].size()
	stats["demand_supply_updates"] = get_state("demand_supply_history", []).size()
	stats["inflation_deflation_events"] = get_state("inflation_deflation_history", []).size()
	stats["market_trend_changes"] = get_state("market_trend_history", []).size()
	set_state("economy_statistics", stats)

func get_economy_statistics() -> Dictionary:
	update_economy_statistics()
	return get_state("economy_statistics", {})

func get_price_history(item: String) -> Array:
	var history = get_state("price_history", {})
	return history.get(item, [])
