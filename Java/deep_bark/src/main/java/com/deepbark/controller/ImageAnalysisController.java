package com.deepbark.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class ImageAnalysisController {
    private static final Logger logger = LoggerFactory.getLogger(ImageAnalysisController.class);

    @Value("${flask.server.url}")
    private String flaskServerUrl;

    private final RestTemplate restTemplate;

    public ImageAnalysisController(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    @PostMapping("/analyze")
    public ResponseEntity<?> analyzeImage(@RequestParam("image") MultipartFile image) {
        try {
            logger.info("=== 이미지 분석 요청 ===");
            logger.info("파일명: {}", image.getOriginalFilename());
            logger.info("파일 크기: {} bytes", image.getSize());

            // Flask 서버로 요청을 보내기 위한 헤더 설정
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);

            // MultipartFile을 Flask 서버로 전송하기 위한 바디 생성
            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            body.add("image", new ByteArrayResource(image.getBytes()) {
                @Override
                public String getFilename() {
                    return image.getOriginalFilename();
                }
            });

            // Flask 서버로 요청 전송
            logger.info("Flask 서버로 요청 전송: {}", flaskServerUrl + "/classify");
            HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);
            ResponseEntity<Map> response = restTemplate.exchange(
                    flaskServerUrl + "/classify",
                    HttpMethod.POST,
                    requestEntity,
                    Map.class);

            logger.info("Flask 서버 응답: {}", response.getBody());
            return ResponseEntity.ok(response.getBody());
        } catch (IOException e) {
            logger.error("이미지 처리 중 오류 발생: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "이미지 처리 중 오류가 발생했습니다: " + e.getMessage()));
        } catch (Exception e) {
            logger.error("서버 오류: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "서버 오류가 발생했습니다: " + e.getMessage()));
        }
    }
}