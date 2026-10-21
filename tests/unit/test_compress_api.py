from io import BytesIO

from PIL import Image

from backend.image_converter.presentation.web.server import app


def test_When_CompressingToJpeg_Expect_OutputUsesJpegExtension():
    buf = BytesIO()
    Image.new("RGB", (32, 32), (200, 50, 50)).save(buf, format="PNG")
    buf.seek(0)

    client = app.test_client()
    res = client.post(
        "/api/compress",
        data={"format": "jpeg", "quality": "85", "files[]": (buf, "photo.png")},
        content_type="multipart/form-data",
    )

    assert res.status_code == 200
    assert res.get_json()["converted_files"] == ["photo.jpeg"]
