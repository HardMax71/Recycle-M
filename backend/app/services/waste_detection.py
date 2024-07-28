# /app/services/waste_collection.py


# TODO: implement detecting waste type
async def detect_waste_type(image_data: bytes):
    # Integrate with an image recognition API to detect waste type
    # api_url = f"{settings.WASTE_DETECTION_API_URL}/detect"
    # files = {'file': image_data}
    # response = requests.post(api_url, files=files)
    # response.raise_for_status()
    # return response.json().get("waste_type")
    return "plastic"
