package com.deepbark.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "dog_breeds")
@Getter
@Setter
public class DogBreed {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String nameEn; // 영어 이름

    @Column(nullable = false)
    private String nameKo; // 한국어 이름

    private String originEn; // 영어 원산지
    private String originKo; // 한국어 원산지

    private String sizeEn; // 영어 크기
    private String sizeKo; // 한국어 크기

    private String lifespanEn; // 영어 수명
    private String lifespanKo; // 한국어 수명

    private String weight; // 무게

    @Column(columnDefinition = "TEXT")
    private String descriptionEn; // 영어 설명

    @Column(columnDefinition = "TEXT")
    private String descriptionKo; // 한국어 설명
}