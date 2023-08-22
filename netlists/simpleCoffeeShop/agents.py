from enforce_typing import enforce_types
from engine import AgentBase
import random

@enforce_types
class CoffeeBuyingAgent(AgentBase.AgentBaseNoEvm):
    def __init__(self, name: str, coffee_likeness: float):
        super().__init__(name, USD=float('inf'), OCEAN=0.0)
        self.coffee_likeness = coffee_likeness
    
    def takeStep(self, state):
        #if state.tick % state.ss.s_per_day == 0:
        buy_chance = self.coffee_likeness
        chance = random.random() 
        #print("chance ", chance)
        #print("buy_chance ", buy_chance)
        if chance < buy_chance:
            coffee_shop = state.getAgent("coffee_shop")
            coffee_cost = 4.0  # Adjust as needed
            self._transferUSD(coffee_shop, coffee_cost)

@enforce_types
class CoffeeShop(AgentBase.AgentBaseNoEvm):
    def __init__(self, name: str):
        super().__init__(name, USD=0.0, OCEAN=0.0)
    
    def takeStep(self, state):
        pass  # Coffee shop doesn't need to take any action

