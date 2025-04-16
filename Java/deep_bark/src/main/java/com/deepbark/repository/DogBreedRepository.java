package com.deepbark.repository;

import com.deepbark.entity.DogBreed;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DogBreedRepository extends JpaRepository<DogBreed, Long> {

    // 영어 이름으로 부분 검색 (대소문자 구분 없음)
    List<DogBreed> findByNameEnContainingIgnoreCase(String nameEn);

    // 한글 이름으로 부분 검색 (대소문자 구분 없음)
    List<DogBreed> findByNameKoContainingIgnoreCase(String nameKo);

    // 영어 크기로 검색
    List<DogBreed> findBySizeEn(String sizeEn);

    // 한글 크기로 검색
    List<DogBreed> findBySizeKo(String sizeKo);

    List<DogBreed> findByNameEnContainingIgnoreCaseOrNameKoContainingIgnoreCase(String nameEn, String nameKo);
}
