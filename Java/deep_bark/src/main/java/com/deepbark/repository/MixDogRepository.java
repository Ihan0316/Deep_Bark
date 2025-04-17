package com.deepbark.repository;

import com.deepbark.entity.MixDog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface MixDogRepository extends JpaRepository<MixDog, Long> {
    @Query("SELECT m FROM MixDog m WHERE " +
            "(m.breed1 = :breed1 AND m.breed2 = :breed2) OR " +
            "(m.breed1 = :breed2 AND m.breed2 = :breed1)")
    Optional<MixDog> findByBreeds(@Param("breed1") String breed1, @Param("breed2") String breed2);
}
