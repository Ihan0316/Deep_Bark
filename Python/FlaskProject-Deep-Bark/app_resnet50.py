# import os
# import torch
# import torchvision.transforms as transforms
# from flask import Flask, request, jsonify, render_template
# from PIL import Image
# from model import load_model
#
# # Flask 앱 생성
# app = Flask(__name__)
# app.config["UPLOAD_FOLDER"] = "static/uploads"
# os.makedirs(app.config["UPLOAD_FOLDER"], exist_ok=True)
#
# # 모델 로드
# model = load_model()
#
# # 클래스 이름
# class_names = ["Chihuahua", "Dachshund"]  # 모델에 맞는 클래스 이름으로 변경
#
#
# # 이미지 전처리 함수
# def transform_image(image):
#     # RGBA 이미지를 RGB로 변환
#     if image.mode == 'RGBA':
#         image = image.convert('RGB')
#
#     transform = transforms.Compose([
#         transforms.Resize((224, 224)),
#         transforms.ToTensor(),
#         transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
#     ])
#     return transform(image).unsqueeze(0)  # 배치 차원 추가
#
#
# # 웹페이지 렌더링
# @app.route("/")
# def index():
#     return render_template("index.html")
#
#
# # 이미지 업로드 및 분류 API
# @app.route("/classify", methods=["POST"])
# def classify_image():
#     if "image" not in request.files:
#         return jsonify({"error": "No image file"}), 400
#
#     image_file = request.files["image"]
#     if image_file.filename == "":
#         return jsonify({"error": "No selected file"}), 400
#
#     # 이미지 저장 (선택사항)
#     image_path = os.path.join(app.config["UPLOAD_FOLDER"], image_file.filename)
#     image_file.save(image_path)
#
#     # 이미지 처리 및 예측
#     image = Image.open(image_path)
#     image_tensor = transform_image(image)
#
#     # 모델 예측
#     with torch.no_grad():
#         outputs = model(image_tensor)
#         probabilities = torch.nn.functional.softmax(outputs, dim=1)
#         top_2_prob, top_2_idx = torch.topk(probabilities, 2)
#
#     response_data = {
#         "predictions": [
#             {
#                 "class": class_names[top_2_idx[0][i].item()],
#                 "confidence": round(top_2_prob[0][i].item() * 100, 2)
#             } for i in range(2)
#         ],
#         "image_path": image_path
#     }
#     return jsonify(response_data)
#
#
#
# # Flask 서버 실행
# if __name__ == "__main__":
#     app.run(debug=True)
