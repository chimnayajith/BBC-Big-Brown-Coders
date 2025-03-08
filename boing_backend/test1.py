import asyncio
import websockets

async def test_ws():
    uri = "ws://localhost:8000/ws/location/12345/"
    async with websockets.connect(uri) as ws:
        await ws.send('{"latitude": 12.971598, "longitude": 77.594566}')
        print(await ws.recv())

asyncio.run(test_ws())