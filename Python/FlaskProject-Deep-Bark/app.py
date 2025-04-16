import os
import torch
from flask import Flask, request, jsonify, render_template
from PIL import Image
from model import load_model, predict_image
import logging

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

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
    try:
        logger.info("=== 이미지 분류 요청 ===")
        
        if "image" not in request.files:
            logger.error("이미지 파일이 없음")
            return jsonify({"error": "No image file"}), 400

        image_file = request.files["image"]
        if image_file.filename == "":
            logger.error("선택된 파일이 없음")
            return jsonify({"error": "No selected file"}), 400

        logger.info(f"업로드된 파일: {image_file.filename}")

        # 파일 확장자 검사
        allowed_extensions = {'jpg', 'jpeg', 'png', 'heif'}
        file_ext = image_file.filename.rsplit('.', 1)[1].lower() if '.' in image_file.filename else ''
        if file_ext not in allowed_extensions:
            logger.error(f"잘못된 파일 형식: {file_ext}")
            return jsonify({"error": f"Invalid file type. Allowed types: {', '.join(allowed_extensions)}"}), 400

        # 이미지 저장
        image_path = os.path.join(app.config["UPLOAD_FOLDER"], image_file.filename)
        image_file.save(image_path)
        logger.info(f"이미지 저장 완료: {image_path}")

        # 이미지 처리 및 예측
        try:
            # 이미지 차원 검사 및 변환
            image = Image.open(image_path)
            if image.mode != 'RGB':
                logger.info("이미지를 RGB로 변환")
                image = image.convert('RGB')
                image.save(image_path)

            # 새로운 predict_image 함수 사용
            predicted_labels, class_probs = predict_image(image_path, model, device, class_names)
            logger.info(f"예측 결과: {predicted_labels}")

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
            logger.info(f"응답 데이터: {response_data}")
            return jsonify(response_data)
        except Exception as e:
            logger.error(f"예측 중 오류 발생: {e}")
            return jsonify({"error": f"이미지 처리 중 오류가 발생했습니다: {str(e)}"}), 500
    except Exception as e:
        logger.error(f"API 처리 중 오류 발생: {e}")
        return jsonify({"error": f"서버 오류가 발생했습니다: {str(e)}"}), 500


# Flask 서버 실행
if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=5000)
