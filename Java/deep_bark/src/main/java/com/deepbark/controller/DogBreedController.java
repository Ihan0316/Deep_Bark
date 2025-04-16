package com.deepbark.controller;

import com.deepbark.entity.DogBreed;
import com.deepbark.repository.DogBreedRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class DogBreedController {

    @Autowired
    private DogBreedRepository dogBreedRepository;

    @GetMapping("/breeds")
    public ResponseEntity<List<DogBreed>> getAllBreeds() {
        List<DogBreed> breeds = dogBreedRepository.findAll();
        return ResponseEntity.ok(breeds);
    }

    @GetMapping("/breeds/search")
    public ResponseEntity<List<DogBreed>> searchBreeds(@RequestParam String query) {
        List<DogBreed> breeds = dogBreedRepository.findByNameEnContainingIgnoreCaseOrNameKoContainingIgnoreCase(query, query);
        return ResponseEntity.ok(breeds);
    }

    @GetMapping("/health")
    public ResponseEntity<String> healthCheck() {
        return ResponseEntity.ok("OK");
    }
} 