import os
import torch
from flask import Flask, request, jsonify, render_template
from PIL import Image
from model import load_model, predict_image

# Flask 앱 생성
app = Flask(__name__)
app.config["UPLOAD_FOLDER"] = "static/uploads"
os.makedirs(app.config["UPLOAD_FOLDER"], exist_ok=True)

# 설정
MODEL_PATH = './model/allbreeds_multi_label_model_b4_remove_BG.pth'

# 클래스 이름
class_names = [
    'Beagle', 'Bichon Frise', 'Border Collie', 'Cavalier King Charles spaniel', 'Chihuahua',
    'ChowChow', 'Cocker Spaniel', 'Dachshund', 'Doberman', 'French Bull Dog',
    'German Shepherd', 'Golden Retriever', 'Italian Greyhound', 'Jindo Dog', 'Malamute',
    'Maltese', 'Miniature Schnauzer', 'Papillon', 'Pekingese', 'Pembroke Welsh Corgi',
    'Pomeranian', 'Pug', 'Samoyed', 'Shiba Inu', 'Shih Tzu', 'Siberian Husky',
    'Standard Poodle', 'Toy Poodle', 'West Highland White Terrier', 'Yorkshire Terrier'
]

# 모델 로드
model, device = load_model(MODEL_PATH, len(class_names))


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
        # 새로운 predict_image 함수 사용
        predicted_labels, class_probs = predict_image(image_path, model, device, class_names)

        # 상위 2개 결과 추출
        sorted_probs = sorted(class_probs.items(), key=lambda x: x[1], reverse=True)
        top_2 = sorted_probs[:2]

        response_data = {
            "predictions": [
                {
                    "class": breed,
                    "confidence": round(confidence, 2)
                } for breed, confidence in top_2
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
