import os
from dotenv import load_dotenv
from motor.motor_asyncio import AsyncIOMotorClient

# Load environment variables from .env file
load_dotenv()

MONGODB_URI = os.getenv("MONGODB_URI", "")

# Global client and db reference
client = None
db = None

def get_database_client():
    global client
    if client is None and MONGODB_URI:
        try:
            client = AsyncIOMotorClient(MONGODB_URI, serverSelectionTimeoutMS=5000)
        except Exception as e:
            print(f"Could not create Motor client with MONGODB_URI: {e}")
            client = None
    return client

def get_database():
    global db
    c = get_database_client()
    if c is not None:
        if db is None:
            # Get default database specified in URI or default to smart_hospital
            db = c.get_default_database(default="smart_hospital")
        return db
    return None

async def create_indexes():
    database = get_database()
    if database is not None:
        try:
            # 1. 2dsphere index on hospitals.location
            await database.hospitals.create_index([("location", "2dsphere")])
            
            # 2. Unique index on users.email
            await database.users.create_index([("email", 1)], unique=True)
            
            # 3. Compound unique index on capacities (hospital_id, resource_type)
            await database.capacities.create_index(
                [("hospital_id", 1), ("resource_type", 1)], 
                unique=True
            )
            
            # 4. Index on requests.status
            await database.requests.create_index([("status", 1)])
            
            print("Database indexes ensured successfully.")
        except Exception as e:
            print(f"Error creating database indexes: {e}")

async def ping_db():
    c = get_database_client()
    if c is not None:
        try:
            await c.admin.command('ping')
            print("MongoDB connected")
            await create_indexes()
        except Exception as e:
            print(f"MongoDB ping failed: {e}")
    else:
        print("MongoDB ping skipped (placeholder MONGODB_URI in .env)")
