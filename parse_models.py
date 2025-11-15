import pandas as pd
import json

xls = pd.ExcelFile('data-models.xlsx')
df = xls.parse('dataModels', header=None)

models = {}
# Row 0 has model names, Row 2 has headers
model_names_row = df.iloc[0].tolist()
headers_row = df.iloc[2].tolist()

# Find column indices for each model (every 6 columns: Model, Field, Type, FK, FK Target, Note)
for col_idx in range(0, len(model_names_row), 6):
    model_name = model_names_row[col_idx]
    if pd.notna(model_name) and str(model_name) not in ['Model', 'x']:
        if model_name not in models:
            models[model_name] = {'fields': []}
        
        # Extract fields for this model (starting from row 3)
        for row_idx in range(3, len(df)):
            field_name = df.iloc[row_idx, col_idx]
            if pd.notna(field_name) and not str(field_name).startswith('Field'):
                # Get corresponding values from adjacent columns
                type_col = col_idx + 1 if col_idx + 1 < len(df.columns) else None
                fk_col = col_idx + 2 if col_idx + 2 < len(df.columns) else None
                fk_target_col = col_idx + 3 if col_idx + 3 < len(df.columns) else None
                note_col = col_idx + 4 if col_idx + 4 < len(df.columns) else None
                
                field_type = df.iloc[row_idx, type_col] if type_col is not None and pd.notna(df.iloc[row_idx, type_col]) else None
                is_fk = df.iloc[row_idx, fk_col] if fk_col is not None and pd.notna(df.iloc[row_idx, fk_col]) else None
                fk_target = df.iloc[row_idx, fk_target_col] if fk_target_col is not None and pd.notna(df.iloc[row_idx, fk_target_col]) else None
                note = df.iloc[row_idx, note_col] if note_col is not None and pd.notna(df.iloc[row_idx, note_col]) else None
                
                if field_type or field_name:  # Only add if there's actual data
                    models[model_name]['fields'].append({
                        'name': str(field_name),
                        'type': str(field_type) if field_type else None,
                        'is_fk': str(is_fk) if is_fk else None,
                        'fk_target': str(fk_target) if fk_target else None,
                        'note': str(note) if note else None
                    })

print(json.dumps(models, indent=2))

