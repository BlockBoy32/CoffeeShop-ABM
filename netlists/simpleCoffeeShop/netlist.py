from enforce_typing import enforce_types
import numpy as np
import  netlists.simpleCoffeeShop.agents as Agents
from engine import KPIsBase, SimStateBase, SimStrategyBase
from util.constants import S_PER_HOUR, S_PER_DAY
from util.plotutil import YParam, arrayToFloatList, LINEAR, MULT1, DOLLAR



@enforce_types
class SimStrategy(SimStrategyBase.SimStrategyBase):
    def __init__(self):
        super().__init__()
        
        self.setTimeStep(S_PER_DAY)
        self.setMaxTime(10, "days")
        self.s_per_day = S_PER_DAY
        self.coffee_likeness_mean = 0.8
        self.coffee_likeness_stddev = 0.25



@enforce_types
class SimState(SimStateBase.SimStateBase):
    def __init__(self, ss=None):
        assert ss is None
        super().__init__(ss)
        
        self.ss = SimStrategy()
        self.coffee_shop = Agents.CoffeeShop("coffee_shop")
        
        self.agents["coffee_shop"] = self.coffee_shop

        for i in range(100):
            coffee_likeness = np.random.normal(self.ss.coffee_likeness_mean, self.ss.coffee_likeness_stddev)
            agent_name = f"coffee_buyer_{i}"
            self.agents[agent_name] = Agents.CoffeeBuyingAgent(agent_name, coffee_likeness)

        self.kpis = CoffeeShopKPIs(self.ss.time_step)



@enforce_types
class CoffeeShopKPIs(KPIsBase.KPIsBase):
    def __init__(self, tick_frequency):
        super().__init__(tick_frequency)
        self.wallet_balance = []
        
    def track(self, state):
        coffee_shop = state.getAgent("coffee_shop")
        self.wallet_balance.append(coffee_shop.USD())


@enforce_types
def netlist_createLogData(state):
    s, dataheader, datarow = [], [], []
    
    coffee_shop = state.getAgent("coffee_shop")
    s.append(f"Coffee Shop Wallet Balance: ${coffee_shop.USD():.2f}")
    dataheader.append("coffee_shop_wallet")
    datarow.append(coffee_shop.USD())

    return s, dataheader, datarow


@enforce_types
def netlist_plotInstructions(header: list[str], values):
    x_label = "Day"
    x = arrayToFloatList(values[:, header.index(x_label)])

    y_params = [
        YParam(["coffee_shop_wallet"], ["Wallet Balance"], "coffee_shop_wallet", LINEAR, MULT1, DOLLAR),
    ]

    return (x_label, x, y_params)
