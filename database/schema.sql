-- Users table
CREATE TABLE public.users (
    id BIGINT NOT NULL,
    fname VARCHAR(255) NOT NULL,
    sname VARCHAR(255) NOT NULL,
    profile_picture TEXT NOT NULL,
    bio TEXT,
    created_at TIMESTAMP NOT NULL,
    CONSTRAINT users_pkey PRIMARY KEY (id)
);

-- Recommendations table
CREATE TABLE public.recommendations (
    id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    caption TEXT,
    category VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL,
    CONSTRAINT recommendations_pkey PRIMARY KEY (id),
    CONSTRAINT recommendations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);

-- Collections table
CREATE TABLE public.collections (
    id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL,
    CONSTRAINT collections_pkey PRIMARY KEY (id),
    CONSTRAINT collections_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);

-- Collection recommendations table (many-to-many mapping)
CREATE TABLE public.collection_recommendations (
    id BIGINT NOT NULL,
    collection_id BIGINT NOT NULL,
    recommendation_id BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT collection_recommendations_pkey PRIMARY KEY (id),
    CONSTRAINT collection_recommendations_collection_id_fkey FOREIGN KEY (collection_id) REFERENCES public.collections(id) ON DELETE CASCADE,
    CONSTRAINT collection_recommendations_recommendation_id_fkey FOREIGN KEY (recommendation_id) REFERENCES public.recommendations(id) ON DELETE CASCADE,
    CONSTRAINT collection_recommendations_unique UNIQUE (collection_id, recommendation_id)
);

-- Create sequence for IDs
CREATE SEQUENCE public.collection_recommendations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- Set the default value for id to use the sequence
ALTER TABLE ONLY public.collection_recommendations ALTER COLUMN id SET DEFAULT nextval('public.collection_recommendations_id_seq'::regclass);

-- Indexes for better performance
CREATE INDEX idx_recommendations_user_id ON public.recommendations(user_id);
CREATE INDEX idx_collections_user_id ON public.collections(user_id);
CREATE INDEX idx_collection_recommendations_collection_id ON public.collection_recommendations(collection_id);
CREATE INDEX idx_collection_recommendations_recommendation_id ON public.collection_recommendations(recommendation_id);