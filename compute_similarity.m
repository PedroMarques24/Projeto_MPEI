function similarity = compute_similarity(user1, user2, minhash_signatures, num_hashes)
    similarity = sum(minhash_signatures(:, user1) == minhash_signatures(:, user2)) / num_hashes;
end