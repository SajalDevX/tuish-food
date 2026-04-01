/**
 * Geo utilities – Haversine distance and geohash generation.
 */

const EARTH_RADIUS_KM = 6371;

/**
 * Convert degrees to radians.
 */
function toRadians(degrees: number): number {
  return (degrees * Math.PI) / 180;
}

/**
 * Calculate the great‑circle distance in kilometres between two
 * latitude/longitude pairs using the Haversine formula.
 */
export function haversineDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const dLat = toRadians(lat2 - lat1);
  const dLon = toRadians(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRadians(lat1)) *
      Math.cos(toRadians(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return EARTH_RADIUS_KM * c;
}

// ── Geohash generation ──────────────────────────────────────────────────────

const BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz";

/**
 * Generate a geohash string of the requested precision (default 9 characters,
 * which is ~5 m accuracy – good for delivery‑partner look‑ups).
 */
export function generateGeohash(
  latitude: number,
  longitude: number,
  precision = 9
): string {
  const latRange: [number, number] = [-90, 90];
  const lonRange: [number, number] = [-180, 180];

  let hash = "";
  let bit = 0;
  let idx = 0;
  let isLon = true;

  while (hash.length < precision) {
    if (isLon) {
      const mid = (lonRange[0] + lonRange[1]) / 2;
      if (longitude >= mid) {
        idx = idx * 2 + 1;
        lonRange[0] = mid;
      } else {
        idx = idx * 2;
        lonRange[1] = mid;
      }
    } else {
      const mid = (latRange[0] + latRange[1]) / 2;
      if (latitude >= mid) {
        idx = idx * 2 + 1;
        latRange[0] = mid;
      } else {
        idx = idx * 2;
        latRange[1] = mid;
      }
    }

    isLon = !isLon;
    bit++;

    if (bit === 5) {
      hash += BASE32[idx];
      bit = 0;
      idx = 0;
    }
  }

  return hash;
}

/**
 * Calculate bounding‑box geohash neighbours for a given centre point and
 * radius in km.  Returns an array of geohash prefixes that cover the area.
 *
 * This is a simplified approach: we compute the geohash of the four corners
 * of the bounding box plus the centre and deduplicate prefixes.
 */
export function geohashesForRadius(
  latitude: number,
  longitude: number,
  radiusKm: number,
  precision = 5
): string[] {
  // Approximate degree offsets
  const latDelta = radiusKm / 110.574;
  const lonDelta = radiusKm / (111.32 * Math.cos(toRadians(latitude)));

  const points: [number, number][] = [
    [latitude, longitude],
    [latitude + latDelta, longitude],
    [latitude - latDelta, longitude],
    [latitude, longitude + lonDelta],
    [latitude, longitude - lonDelta],
    [latitude + latDelta, longitude + lonDelta],
    [latitude + latDelta, longitude - lonDelta],
    [latitude - latDelta, longitude + lonDelta],
    [latitude - latDelta, longitude - lonDelta],
  ];

  const hashes = new Set<string>();
  for (const [lat, lon] of points) {
    hashes.add(generateGeohash(lat, lon, precision));
  }

  return Array.from(hashes);
}
