package com.deepbark.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.*;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
public class PythonService {

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;
    private static final String PYTHON_SERVER_URL = "http://localhost:5000/classify";

    public PythonService() {
        this.restTemplate = new RestTemplate();
        this.objectMapper = new ObjectMapper();
    }

    public String analyzeImage(Path imagePath) {
        try {
            // Python 서버로 이미지 전송
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);

            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            body.add("image", new org.springframework.core.io.FileSystemResource(imagePath.toFile()));

            HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);

            ResponseEntity<String> response = restTemplate.exchange(
                    PYTHON_SERVER_URL,
                    HttpMethod.POST,
                    requestEntity,
                    String.class);

            // Python 서버의 응답을 Flutter 앱이 기대하는 형식으로 변환
            Map<String, Object> pythonResponse = objectMapper.readValue(response.getBody(), Map.class);
            List<Map<String, Object>> predictions = (List<Map<String, Object>>) pythonResponse.get("predictions");

            List<Map<String, Object>> breeds = new ArrayList<>();
            for (Map<String, Object> prediction : predictions) {
                Map<String, Object> breed = new java.util.HashMap<>();
                breed.put("nameEn", prediction.get("class"));
                breed.put("nameKo", getKoreanName((String) prediction.get("class")));
                breed.put("confidence", prediction.get("confidence"));
                breed.put("imageUrl", "assets/images/" + prediction.get("class").toString().toLowerCase() + ".jpg");
                breeds.add(breed);
            }

            return objectMapper.writeValueAsString(breeds);
        } catch (Exception e) {
            throw new RuntimeException("Python 서버와 통신 중 오류가 발생했습니다.", e);
        }
    }

    private String getKoreanName(String englishName) {
        // 영어 이름을 한글 이름으로 변환하는 로직
        Map<String, String> nameMap = new java.util.HashMap<>();
        nameMap.put("Beagle", "비글");
        nameMap.put("Bichon Frise", "비숑 프리제");
        nameMap.put("Border Collie", "보더 콜리");
        nameMap.put("Cavalier King Charles spaniel", "카발리에 킹 찰스 스패니얼");
        nameMap.put("Chihuahua", "치와와");
        nameMap.put("ChowChow", "차우차우");
        nameMap.put("Cocker Spaniel", "코커 스패니얼");
        nameMap.put("Dachshund", "닥스훈트");
        nameMap.put("Doberman", "도베르만");
        nameMap.put("French Bull Dog", "프렌치 불독");
        nameMap.put("German Shepherd", "저먼 셰퍼드");
        nameMap.put("Golden Retriever", "골든 리트리버");
        nameMap.put("Italian Greyhound", "이탈리안 그레이하운드");
        nameMap.put("Jindo Dog", "진돗개");
        nameMap.put("Malamute", "알래스칸 말라뮤트");
        nameMap.put("Maltese", "말티즈");
        nameMap.put("Miniature Schnauzer", "미니어처 슈나우저");
        nameMap.put("Papillon", "파피용");
        nameMap.put("Pekingese", "페키니즈");
        nameMap.put("Pembroke Welsh Corgi", "웰시 코기");
        nameMap.put("Pomeranian", "포메라니안");
        nameMap.put("Pug", "퍼그");
        nameMap.put("Samoyed", "사모예드");
        nameMap.put("Shiba Inu", "시바견");
        nameMap.put("Shih Tzu", "시츄");
        nameMap.put("Siberian Husky", "시베리안 허스키");
        nameMap.put("Standard Poodle", "스탠다드 푸들");
        nameMap.put("Toy Poodle", "토이 푸들");
        nameMap.put("West Highland White Terrier", "웨스트 하이랜드 화이트 테리어");
        nameMap.put("Yorkshire Terrier", "요크셔 테리어");

        return nameMap.getOrDefault(englishName, englishName);
    }
}