import torch
import torch.nn as nn
import timm


def load_model(model_path="model/allbreeds_multi_label_model_b3.pth", num_classes=30):
    """
    EfficientNet-B3 모델을 로드하고 저장된 가중치를 적용합니다.

    Args:
        model_path (str): 모델 가중치 파일 경로
        num_classes (int): 클래스 수

    Returns:
        torch.nn.Module: 학습된 모델
    """
    # EfficientNet-B3 모델 생성
    model = timm.create_model('efficientnet_b3', pretrained=False)

    # 저장된 모델과 동일한 시퀀셜 구조의 classifier 레이어 생성
    in_features = model.classifier.in_features
    model.classifier = nn.Sequential(
        nn.Linear(in_features, 512),
        nn.ReLU(),
        nn.Dropout(0.5),
        nn.Linear(512, num_classes)
    )

    try:
        # 가중치 로드
        state_dict = torch.load(model_path, map_location=torch.device('cpu'))

        # 'model.' 접두사 처리
        if any(k.startswith('model.') for k in state_dict.keys()):
            new_state_dict = {k.replace('model.', ''): v for k, v in state_dict.items()}
            model.load_state_dict(new_state_dict, strict=False)
        else:
            model.load_state_dict(state_dict, strict=False)

        print(f"모델이 성공적으로 로드되었습니다: {model_path}")
    except Exception as e:
        print(f"모델 로드 중 오류 발생: {e}")
        print("오류가 있지만 부분적으로 로드된 모델을 사용합니다.")

    model.eval()
    return model
