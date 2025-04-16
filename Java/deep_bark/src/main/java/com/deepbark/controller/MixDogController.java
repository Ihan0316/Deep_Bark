package com.deepbark.controller;

import com.deepbark.entity.MixDog;
import com.deepbark.repository.MixDogRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Optional;

@RestController
@RequestMapping("/api/mix-dogs")
public class MixDogController {
    @Autowired
    private MixDogRepository mixDogRepository;

    @GetMapping("/find")
    public ResponseEntity<?> findMixDog(
            @RequestParam String breed1,
            @RequestParam String breed2) {
        Optional<MixDog> mixDog = mixDogRepository.findByBreeds(breed1, breed2);
        return mixDog.map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}
