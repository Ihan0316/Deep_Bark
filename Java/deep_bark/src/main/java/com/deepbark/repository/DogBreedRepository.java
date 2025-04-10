package com.deepbark.repository;

import com.deepbark.entity.DogBreed;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface DogBreedRepository extends JpaRepository<DogBreed, Long> {
    List<DogBreed> findByNameContainingIgnoreCase(String name);
    
    @Query("SELECT d FROM DogBreed d WHERE " +
           "LOWER(d.name) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
           "LOWER(d.description) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
           "LOWER(d.characteristics) LIKE LOWER(CONCAT('%', :keyword, '%'))")
    List<DogBreed> searchBreeds(@Param("keyword") String keyword);
    
    List<DogBreed> findBySize(String size);
    List<DogBreed> findByTemperament(String temperament);
} 