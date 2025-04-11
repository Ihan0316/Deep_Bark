# from flask import Flask, request, jsonify
# from werkzeug.utils import secure_filename
# import os
# from model import load_model, predict_image
#
# app = Flask(__name__)
#
# # 설정
# UPLOAD_FOLDER = 'uploads'
# ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}
# # B3에서 B4로 모델 경로 변경
# MODEL_PATH = 'efficientnet_b4_배경제거_컷_증강/maltipoo_multi_label_model_b4.pth'
#
# app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
# os.makedirs(UPLOAD_FOLDER, exist_ok=True)
#
# # 전체 순종 리스트 (30종)
# LABEL_NAMES = [
#     'Beagle', 'Bichon Frise', 'Border Collie', 'Cavalier King Charles spaniel', 'Chihuahua',
#     'ChowChow', 'Cocker Spaniel', 'Dachshund', 'Doberman', 'French Bull Dog',
#     'German Shepherd', 'Golden Retriever', 'Italian Greyhound', 'Jindo Dog', 'Malamute',
#     'Maltese', 'Miniature Schnauzer', 'Papillon', 'Pekingese', 'Pembroke Welsh Corgi',
#     'Pomeranian', 'Pug', 'Samoyed', 'Shiba Inu', 'Shih Tzu', 'Siberian Husky',
#     'Standard Poodle', 'Toy Poodle', 'West Highland White Terrier', 'Yorkshire Terrier'
# ]
#
# # 모델 로드
# model, device = load_model(MODEL_PATH, len(LABEL_NAMES))
#
#
# def allowed_file(filename):
#     return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS
#
#
# @app.route('/predict', methods=['POST'])
# def predict():
#     if 'file' not in request.files:
#         return jsonify({'error': 'No file part'}), 400
#     file = request.files['file']
#     if file.filename == '':
#         return jsonify({'error': 'No selected file'}), 400
#     if file and allowed_file(file.filename):
#         filename = secure_filename(file.filename)
#         file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
#         file.save(file_path)
#
#         predicted_labels, class_probs = predict_image(file_path, model, device, LABEL_NAMES)
#
#         result = {
#             'predicted_labels': predicted_labels,
#             'class_probabilities': class_probs
#         }
#         return jsonify(result)
#     return jsonify({'error': 'Invalid file type'}), 400
#
#
# if __name__ == '__main__':
#     app.run(debug=True, host='0.0.0.0', port=5000)
