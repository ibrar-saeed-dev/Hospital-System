import asyncio
from seed import seed
from seed_requests import seed_requests

async def reset_demo():
    print("=== RESETTING DEMO ENVIRONMENT TO CLEAN STATE ===")
    await seed()
    await seed_requests()
    print("=== DEMO ENVIRONMENT RESET COMPLETE ===")

if __name__ == "__main__":
    asyncio.run(reset_demo())
