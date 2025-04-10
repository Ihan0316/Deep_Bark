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
    private String name;

    @Column(length = 1000)
    private String description;

    private String imageUrl;

    @Column(length = 1000)
    private String characteristics;

    private String size;
    private String temperament;
    private String lifeSpan;
    private String origin;
} 