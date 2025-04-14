import os
import torch
import torchvision.transforms as transforms
from flask import Flask, request, jsonify, render_template
from PIL import Image
from model_b3 import load_model

# Flask 앱 생성
app = Flask(__name__)
app.config["UPLOAD_FOLDER"] = "static/uploads"
os.makedirs(app.config["UPLOAD_FOLDER"], exist_ok=True)

# 모델 로드
model = load_model()

# 클래스 이름
class_names = [
    'Beagle', 'Bichon Frise', 'Border Collie', 'Cavalier King Charles spaniel', 'Chihuahua',
    'ChowChow', 'Cocker Spaniel', 'Dachshund', 'Doberman', 'French Bull Dog',
    'German Shepherd', 'Golden Retriever', 'Italian Greyhound', 'Jindo Dog', 'Malamute',
    'Maltese', 'Miniature Schnauzer', 'Papillon', 'Pekingese', 'Pembroke Welsh Corgi',
    'Pomeranian', 'Pug', 'Samoyed', 'Shiba Inu', 'Shih Tzu', 'Siberian Husky',
    'Standard Poodle', 'Toy Poodle', 'West Highland White Terrier', 'Yorkshire Terrier'
]

# 이미지 전처리 함수
def transform_image(image):
    # RGBA 이미지를 RGB로 변환
    if image.mode == 'RGBA':
        image = image.convert('RGB')

    # EfficientNet-B3에 맞는 이미지 크기로 변경 (300x300)
    transform = transforms.Compose([
        transforms.Resize((300, 300)),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
    ])
    return transform(image).unsqueeze(0)  # 배치 차원 추가

# 웹페이지 렌더링
@app.route("/")
def index():
    return render_template("index.html")

# 이미지 업로드 및 분류 API
@app.route("/classify", methods=["POST"])
def classify_image():
    if "image" not in request.files:
        return jsonify({"error": "No image file"}), 400

    image_file = request.files["image"]
    if image_file.filename == "":
        return jsonify({"error": "No selected file"}), 400

    # 이미지 저장
    image_path = os.path.join(app.config["UPLOAD_FOLDER"], image_file.filename)
    image_file.save(image_path)

    # 이미지 처리 및 예측
    try:
        image = Image.open(image_path)
        image_tensor = transform_image(image)

        # 모델 예측
        with torch.no_grad():
            outputs = model(image_tensor)
            # 다중 레이블 분류인 경우 시그모이드 사용
            probabilities = torch.sigmoid(outputs)
            top_2_prob, top_2_idx = torch.topk(probabilities[0], 2)

        response_data = {
            "predictions": [
                {
                    "class": class_names[top_2_idx[i].item()],
                    "confidence": round(float(top_2_prob[i].item()) * 100, 2)
                } for i in range(2)
            ],
            "image_path": image_path
        }
        return jsonify(response_data)
    except Exception as e:
        print(f"예측 중 오류 발생: {e}")
        return jsonify({"error": f"이미지 처리 중 오류가 발생했습니다: {str(e)}"}), 500

# Flask 서버 실행
if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=5000)
