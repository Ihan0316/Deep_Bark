import torch
import torch.nn as nn
import timm
from PIL import Image
import torchvision.transforms as transforms


class MultiLabelModel(nn.Module):
    def __init__(self, num_labels):
        super(MultiLabelModel, self).__init__()
        # B3에서 B4로 변경
        self.model = timm.create_model('efficientnet_b4', pretrained=False)
        in_features = self.model.classifier.in_features
        self.model.classifier = nn.Sequential(
            nn.Linear(in_features, 512),
            nn.ReLU(),
            nn.Dropout(0.5),
            nn.Linear(512, num_labels)
        )

    def forward(self, x):
        return self.model(x)


def load_model(model_path, num_labels):
    device = torch.device(
        "mps" if torch.backends.mps.is_available() else "cuda" if torch.cuda.is_available() else "cpu")
    model = MultiLabelModel(num_labels)
    model.load_state_dict(torch.load(model_path, map_location=device))
    model.to(device)
    model.eval()
    return model, device


def predict_image(image_path, model, device, label_names, threshold=0.5):
    # 리사이즈를 300에서 380으로 변경
    transform = transforms.Compose([
        transforms.Resize((380, 380)),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
    ])

    # RGBA 이미지를 RGB로 변환
    image = Image.open(image_path)
    if image.mode == 'RGBA':
        image = image.convert('RGB')

    image_tensor = transform(image).unsqueeze(0).to(device)

    with torch.no_grad():
        outputs = model(image_tensor)
        probs = torch.sigmoid(outputs)[0]

        predicted_labels = []
        class_probs = {}

        for i, prob in enumerate(probs):
            class_prob = float(prob.item()) * 100
            class_probs[label_names[i]] = class_prob
            if class_prob > threshold * 100:
                predicted_labels.append(label_names[i])

        return predicted_labels, class_probs
