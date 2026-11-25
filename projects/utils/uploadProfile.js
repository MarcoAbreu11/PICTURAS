// Checks the caller's profile before a video upload body is read.
const { videoSizeLimitBytes } = require("./video");

// Middleware factory. `lookupType(req)` resolves to the caller's profile type
// ("anonymous", "free", "premium"). The type is stored in req.uploadUserType
// so the size limit can be enforced while streaming. Profiles that cannot
// upload videos are rejected before any of the body is read, and a failed
// lookup refuses the upload instead of letting it run without a limit.
function requireVideoProfile(lookupType) {
  return async (req, res, next) => {
    try {
      req.uploadUserType = await lookupType(req);
    } catch (_) {
      return res.status(503).jsonp("Could not check your profile. Please try again later.");
    }
    if (!videoSizeLimitBytes(req.uploadUserType)) {
      return res.status(403).jsonp("Anonymous users cannot upload videos. Create an account to edit video.");
    }
    next();
  };
}

module.exports = { requireVideoProfile };
