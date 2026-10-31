// Import component styles so the landing page layout and branding apply.
import "./App.css";

// Import logo assets. Vite will process these imports into bundled URLs at build time.
import codewrkxLogo from "./assets/codewrkx-logo.png";
import awsLogo from "./assets/aws.png";

// Root React component rendered by main.jsx into the #root element.
function App() {
  return (
    // Page shell: centres content vertically and horizontally.
    <div className="app">

      {/* Event / cohort context line shown above the brand cards. */}
      <h3 className="bootcamp-title">
        AWS Graduate Cloud Skills Accelerator | Online
      </h3>

      {/* Brand row: Academy and AWS visual identity. */}
      <div className="cards">
        <div className="card">
          <img
            src={codewrkxLogo}
            alt="CodeWrkx Academy"
          />
        </div>

        <div className="card">
          <img
            src={awsLogo}
            alt="AWS"
          />
        </div>
      </div>

      {/* Primary programme banner. */}
      <div className="banner">
        <h1>
          <span>#AWS </span>
          <span className="gradient">
            ACCELERATOR
          </span>
        </h1>
      </div>

      {/* Supporting value statement. */}
      <p className="tagline">
        Building the Next Generation of Cloud Engineers.
      </p>

    </div>
  );
}

// Export so main.jsx can mount this component.
export default App;